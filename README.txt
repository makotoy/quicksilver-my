This project forked from the experimental version of Quicksilver. It
differs from the released version (B5X) in the following ways:

  * Triggers are moving to a separate product, called Catalyst

  * All the little frameworks are being joined into one big one called
    Crucible. This includes extensions and core functionality that
    most apps and plugins will use. This is currently called
    QSCrucible.framework.

  * The preferences are going to get MUCH simpler. There will be
    Extras-style advanced prefs for the fiddly options.

  * There is a new plugin architecture called Elements, realized by
    the QSElements.framework.  Plugins are going to be hidden from
    most users, they'll activate themselves automatically or be
    installable from the web

  * The old plugins for B5X version of Quicksilver is not compatible
    with the current version, although the immigration should be easy.

  --------------------------------

Crucible: A framework with extension to AppKit and tools common to all
	Alchemy apps

Elements: A framework supporting the plugin architecture
	
Quicksilver: Command window driven launcher
	
Catalyst: Triggers preference pane

AdditionalElements: Additional plugins for Quicksilver
