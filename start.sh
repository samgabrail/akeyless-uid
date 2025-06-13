#!/bin/bash

# Change to demo directory
cd demo

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to show header
show_header() {
    clear
    echo -e "${BLUE}🚀 Akeyless Universal Identity - Interactive Demo${NC}"
    echo "=========================================================="
    echo ""
    echo -e "${YELLOW}This guided demo follows the realistic workflow diagram:${NC}"
    echo -e "  🧑‍💼 Admin → 👷 Platform Engineer → 🚀 Application Service"
    echo ""
}

# Function to check if prerequisites are met
check_prerequisites() {
    if [ -z "$AKEYLESS_ACCESS_ID" ] || [ -z "$AKEYLESS_ACCESS_KEY" ]; then
        echo -e "${RED}⚠️  Prerequisites Required:${NC}"
        echo "   export AKEYLESS_ACCESS_ID=\"your-access-id\""
        echo "   export AKEYLESS_ACCESS_KEY=\"your-access-key\""
        echo ""
        echo "Set these environment variables and restart the demo."
        echo ""
        read -p "Press Enter to continue anyway or Ctrl+C to exit..."
    fi
}

# Function to show workflow status
show_status() {
    echo -e "${BLUE}📋 Workflow Status:${NC}"
    
    if [ -f "tokens/client-tokens" ]; then
        echo -e "  ✅ Step 1-3: Admin setup complete"
    else
        echo -e "  ⭕ Step 1-3: Admin setup needed"
    fi
    
    if [ -f "tokens/application-service-token" ]; then
        echo -e "  ✅ Deployment: Platform Engineer complete"
    else
        echo -e "  ⭕ Deployment: Platform Engineer needed"
    fi
    
    if [ -f "logs/rotation.log" ] || [ -f "logs/simple-rotation.log" ]; then
        echo -e "  ✅ Operations: Application Service active"
    else
        echo -e "  ⭕ Operations: Application Service pending"
    fi
    
    echo ""
}

# Function to run admin setup
run_admin_setup() {
    echo -e "${GREEN}🧑‍💼 Running Admin Setup (Steps 1-3)...${NC}"
    echo "Creating UID auth method, generating initial token, provisioning to Platform Engineer"
    echo ""
    ./scripts/admin-setup.sh
    echo ""
    echo -e "${GREEN}✅ Admin setup complete!${NC}"
    read -p "Press Enter to continue..."
}

# Function to run platform deployment
run_platform_deploy() {
    if [ ! -f "tokens/client-tokens" ]; then
        echo -e "${RED}❌ Admin setup required first (tokens/client-tokens not found)${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${GREEN}👷 Running Platform Engineer Deployment...${NC}"
    echo "Deploying tokens to Application Services, setting up automated rotation"
    echo ""
    ./scripts/platform-deploy.sh
    echo ""
    echo -e "${GREEN}✅ Platform deployment complete!${NC}"
    read -p "Press Enter to continue..."
}

# Function to run application service workflow
run_application_service() {
    if [ ! -f "tokens/application-service-token" ]; then
        echo -e "${RED}❌ Platform deployment required first (tokens/application-service-token not found)${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${GREEN}🚀 Running Application Service Workflow (Steps 4-9)...${NC}"
    echo "Autonomous operations: auth with UID token, get t-token, access secrets, self-rotate"
    echo ""
    ./scenarios/client-workflow.sh
    echo ""
    echo -e "${GREEN}✅ Application Service workflow complete!${NC}"
    read -p "Press Enter to continue..."
}

# Function to run hierarchical token management
run_child_tokens() {
    echo -e "${GREEN}🌳 Running Hierarchical Token Management Demo...${NC}"
    echo "Exploring parent-child token relationships and microservice isolation"
    echo ""
    ./scenarios/child-tokens.sh
    echo ""
    echo -e "${GREEN}✅ Hierarchical token demo complete!${NC}"
    read -p "Press Enter to continue..."
}

# Function to run Python integration example
run_python_example() {
    if [ ! -f "tokens/application-service-token" ]; then
        echo -e "${RED}❌ Application service setup required first (tokens/application-service-token not found)${NC}"
        echo "Please run Platform Engineer deployment first."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Check if Python 3 is available
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 is required for this demo${NC}"
        echo "Please install Python 3 and try again."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${GREEN}🐍 Running Python Integration Example...${NC}"
    echo "Demonstrating real-world secretless authentication in Python applications"
    echo ""
    python3 ./examples/machine-auth.py
    echo ""
    echo -e "${GREEN}✅ Python integration example complete!${NC}"
    read -p "Press Enter to continue..."
}

# Function to show main menu
show_menu() {
    show_header
    check_prerequisites
    show_status
    
    echo -e "${BLUE}🎭 Choose Your Demo Experience:${NC}"
    echo ""
    echo -e "  ${YELLOW}Persona Steps:${NC}"
    echo "    1) 🧑‍💼 Admin Setup (Steps 1-3)"
    echo "    2) 👷 Platform Engineer Deployment"
    echo "    3) 🚀 Application Service Operations (Steps 4-9)"
    echo ""
    echo -e "  ${YELLOW}Advanced Features:${NC}"
    echo "    4) 🌳 Hierarchical Token Management"
    echo "    5) 🐍 Python Integration Example"
    echo ""
    echo "    6) 📊 Show Workflow Status"
    echo "    7) 🚪 Exit"
    echo ""
}

# Main interactive loop
while true; do
    show_menu
    read -p "Enter your choice (1-7): " choice
    echo ""
    
    case $choice in
        1)
            run_admin_setup
            ;;
        2)
            run_platform_deploy
            ;;
        3)
            run_application_service
            ;;
        4)
            run_child_tokens
            ;;
        5)
            run_python_example
            ;;
        6)
            show_header
            show_status
            read -p "Press Enter to continue..."
            ;;
        7)
            echo -e "${GREEN}Thank you for exploring Akeyless Universal Identity!${NC}"
            echo ""
            echo -e "${BLUE}🚀 Next Steps:${NC}"
            echo "  • Review generated tokens in ./tokens/"
            echo "  • Check rotation logs in ./logs/"
            echo "  • Explore implementation examples in ./examples/"
            echo "  • Read the complete blog post: ../blog-post.md"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter a number 1-7.${NC}"
            read -p "Press Enter to try again..."
            ;;
    esac
done