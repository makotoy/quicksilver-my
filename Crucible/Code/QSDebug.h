/*
 *  QSDebug.h
 *  Quicksilver
 *
 *  Created by Alcor on 2/2/05.
 *  Copyright 2005 Blacktree. All rights reserved.
 *
 */

#define VERBOSE (getenv("verbose") != NULL)
#define DEBUG (bool)getenv("NSDebugEnabled")

#define DEBUG_RANKING (getenv("QSDebugRanking") != NULL)
#define DEBUG_MNEMONICS (getenv("QSDebugMnemonics") != NULL)
#define DEBUG_PLUGINS (getenv("QSDebugPlugIns") != NULL)
#define DEBUG_MEMORY (getenv("QSDebugMemory") != NULL)
#define DEBUG_STARTUP (getenv("QSDebugStartup") != NULL)
#define DEBUG_CATALOG (getenv("QSDebugCatalog") != NULL)
