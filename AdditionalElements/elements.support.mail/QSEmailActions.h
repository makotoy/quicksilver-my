/* QSEmailActions.h */
/* QuickSilver Gamma project, derived from Blacktree codebase */
/* Makoto Yamashita 2015 */

#import <Foundation/Foundation.h>
#import <QSCrucible/QSCrucible.h>

@interface QSEmailActions : QSActionProvider {

}
- (QSObject *) sendEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject;
- (QSObject *) composeEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject;
- (QSObject *) composeEmailTo:(QSObject *)dObject withItem:(QSObject *)iObject sendNow:(BOOL)sendNow direct:(BOOL)direct;
@end
