# Quicksilver-my

## For developers

See the project wiki covers for developer info, such as building instructions and guide for plugin migration from the released version of quicksilver.

## Overview

This project forked from the experimental version of Quicksilver. It differs from the released version (B5X) in the following ways:

* Triggers are moving to a separate product, called Catalyst
* All the little frameworks are being joined into one big one called Crucible. This includes extensions and core functionality that most apps and plugins will use. This is currently called QSCrucible.framework.
* The preferences are going to get MUCH simpler. There will be Extras-style advanced prefs for the fiddly options.
* There is a new plugin architecture called Elements, realized by the QSElements.framework.  Plugins are going to be hidden from most users, they'll activate themselves automatically or be installable from the web.
* The old plugins for B5X version of Quicksilver is not compatible with the current version, although the immigration should be easy.

### Components

* _Crucible_: A framework with extension to AppKit and tools common to all Alchemy apps
* _Elements_: A framework supporting the plugin architecture
* _Quicksilver_: Command window driven launcher
* _Catalyst_: Triggers preference pane
* _AdditionalElements_: Additional plugins for Quicksilver
