# Cyware packages

[![Slack](https://img.shields.io/badge/slack-join-blue.svg)](https://cyware.khulnasoft.com/community/join-us-on-slack/)
[![Email](https://img.shields.io/badge/email-join-blue.svg)](https://groups.google.com/forum/#!forum/cyware)
[![Documentation](https://img.shields.io/badge/docs-view-green.svg)](https://documentation.cyware.khulnasoft.com)
[![Documentation](https://img.shields.io/badge/web-view-green.svg)](https://cyware.khulnasoft.com)

Cyware is an Open Source Host-based Intrusion Detection System that performs log analysis, file integrity monitoring, policy monitoring, rootkit detection, real-time alerting, active response, vulnerability detector, etc.

In this repository, you can find the necessary tools to build a Cyware package for Debian based OS, RPM based OS package, Arch based OS, macOS, RPM packages for IBM AIX, the OVA, and the apps for Kibana and Splunk:

- [AIX](/aix/README.md)
- [Arch](/arch/README.md)
- [Debian](/debs/README.md)
- [HP-UX](/hp-ux/README.md)
- [KibanaApp](/cywareapp/README.md)
- [macOS](/macos/README.md)
- [OVA](/ova/README.md)
- [RPM](/rpms/README.md)
- [SplunkApp](/splunkapp/README.md)
- [Solaris](/solaris/README.md)
- [Windows](/windows/README.md)

## Branches

- `master` branch contains the latest code, be aware of possible bugs on this branch.
- `stable` branch on correspond to the last Cyware stable version.

## Distribution version matrix

The following table shows the references for the versions of each component.

### Cyware dashboard

| Cyware dashboard | Opensearch dashboards |
|-----------------|-----------------------|
| 4.3.x           | 1.2.0                 |
| 4.4.0           | 2.4.1                 |
| 4.4.1 - 4.5.x   | 2.6.0                 |
| 4.6.x - 4.7.x   | 2.8.0                 |
| 4.8.x - current | 2.10.0                |

### Cyware indexer

| Cyware indexer   | Opensearch            |
|-----------------|-----------------------|
| 4.3.x           | 1.2.4                 |
| 4.4.0           | 2.4.1                 |
| 4.4.1 - 4.5.x   | 2.6.0                 |
| 4.6.x - 4.7.x   | 2.8.0                 |
| 4.8.x - current | 2.10.0                |

## Contribute

If you want to contribute to our project please don't hesitate to send a pull request. You can also join our users [mailing list](https://groups.google.com/d/forum/cyware) by sending an email to [cyware+subscribe@googlegroups.com](mailto:cyware+subscribe@googlegroups.com) or join to our Slack channel by filling this [form](https://cyware.khulnasoft.com/community/join-us-on-slack/) to ask questions and participate in discussions.

## License and copyright

CYWARE
Copyright (C) 2015 KhulnaSoft Ltd.  (License GPLv2)
