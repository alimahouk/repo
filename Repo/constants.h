//
//  constants.h
//  Repo
//
//  Created by Ali Mahouk on 12/10/16.
//  Copyright © 2016 saucewipe. All rights reserved.
//

#ifndef CONSTANTS_H
#define CONSTANTS_H

#define DB_TEMPLATE_NAME                @"main.sqlite"
#define DEFAULT_STROKE_COLOR            [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0]
#define DEFAULT_STROKE_SIZE             5.5
#define HASHTAG_URL_PREFIX              @"tag://"
#define ITEM_PREVIEW_SIZE               UIScreen.mainScreen.bounds.size.width / 4
#define LOCATION_UPDATE_INTERVAL        60 * 2
#define THROWING_THRESHOLD              1000

#define NSUDKEY_CAMERA_GRID             @"CameraGrid"
#define NSUDKEY_LAST_SYNC_DATE          @"LastSyncDate"
#define NSUDKEY_TUTORIAL_COLLECTION_POP @"LibraryCollectionPopTutorial"
#define NSUDKEY_TUTORIAL_INK            @"InkTutorial"
#define NSUDKEY_TUTORIAL_NEW_ITEM       @"NewItemTutorial"
#define NSUDKEY_TUTORIAL_TEXT_SIZE      @"NotepadTextSizeTutorial"

typedef enum {
        ItemTypeDocument = 1,
        ItemTypeLink,
        ItemTypeLocation,
        ItemTypeMovie,
        ItemTypePhoto,
        ItemTypeText,
        ItemTypeNone
} ItemType;

typedef enum {
        FlashModeOff = 1,
        FlashModeOn,
        FlashModeAuto
} FlashMode;

#endif /* CONSTANTS_H */
