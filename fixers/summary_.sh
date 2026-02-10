show_completion_summary() {
    echo ""
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                         ACCESS INFORMATION                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Direct Access (via port):"
    echo "    URL: http://${virtual_host}:${host_port}"
    echo ""
}

local virtual_host=$(hostname -I | cut -d' ' -f1)


while [[ $# -gt 0 ]]; do
    case $1 in
        --connection-summary|-cs)
            show_completion_summary
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "kindly please use argument --connection-summary | -cs for your currently installed odoo version information summary"
            exit 1
            ;;
    esac
done