#!/bin/sh

printf "Quick action menu of common operations.

Usage: igm ${RED}|${NC} igm [option] ${RED}|${NC} igm [option] [arg]

[${BLUE}General${NC}]
  igm                               Launch the Income Generator tool.
  igm help                          Display this help usage guide.
  igm version                       Show the current version of Income Generator tool.
  igm update                        Check and update Income Generator tool if available.

[${BLUE}Manage${NC}]
  igm start     [name]              Start one or all currently deployed applications.
  igm stop      [name]              Stop one or all currently deployed running applications.
  igm restart   [name]              Restart a currently deployed running application.
  igm remove    [name]              Stop and remove one or all currently deployed applications.
  igm logs      [name]              Show logs for the selected application.
  igm show      [app|proxy|group]   List installed and running applications, optionally grouped.
  igm deploy                        Launch the install manager for deploying applications.
  igm redeploy                      Redeploy the last installed application state.
  igm clean     [all]               Cleanup orphaned applications, volumes. (all: include orphaned images).

[${BLUE}Proxy${NC}]
  igm proxy                         Launch the proxy tool menu.
  igm proxy setup                   Setup and define list of proxy entries.
  igm proxy app                     Enable or disable proxy applications for deployment.
  igm proxy install                 Install selected proxy applications.
  igm proxy remove                  Remove all currently deployed proxy applications.
  igm proxy reset                   Clear all proxy entries and remove proxy file.
  igm proxy id                      Show active applications with multi-UUIDs and instructions.
  igm proxy limit                   Configure proxy application install limit.

[${BLUE}IP Quality${NC}]
  igm ip                            Analyse IP quality for real IP and all active proxies.

[${BLUE}Configuration${NC}]
  igm app|service                   Enable or disable applications/services for deployment.
  igm setup                         Setup credentials for applications to be deployed.
  igm view                          View all configured application credentials.
  igm edit                          Edit configured credentials and config file directly.
  igm limit                         Set the application resource limits.
  igm editor                        Change the default editor tool to use.
  igm runtime                       Configure or manage the container runtime engine.
"
