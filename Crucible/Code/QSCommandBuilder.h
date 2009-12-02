//  Derived from Blacktree codebase
//  2009-11-30 Makoto Yamashita

// TODO: shouldn't this move to Catalyst?

@interface QSCommandBuilder : QSInterfaceController {
    IBOutlet NSCell * iFrame;
	QSCommand *representedCommand;
}

- (QSCommand *) representedCommand;
- (void) setRepresentedCommand:(QSCommand *)aRepresentedCommand;

- (IBAction) cancel:(id)sender;
- (IBAction) save:(id)sender;
@end
