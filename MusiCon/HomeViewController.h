//
//  HomeViewController.h
//  MusiCon
//
//  Created by Bhanu Verma on 3/27/16.
//  Copyright © 2016 theRecommendables. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>
#import <CoreLocation/CoreLocation.h>
#import <MicrosoftBandKit_iOS/MicrosoftBandKit_iOS.h>

@interface HomeViewController : UIViewController <SPTAudioStreamingPlaybackDelegate,MSBClientManagerDelegate,CLLocationManagerDelegate,UITextViewDelegate>

@end
