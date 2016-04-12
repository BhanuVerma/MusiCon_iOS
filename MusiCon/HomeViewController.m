//
//  HomeViewController.m
//  MusiCon
//
//  Created by Bhanu Verma on 3/27/16.
//  Copyright © 2016 theRecommendables. All rights reserved.
//

#import "HomeViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "MBProgressHUD.h"

@interface HomeViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIImageView *artworkImage;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *circleButton;
@property (weak, nonatomic) IBOutlet UIButton *heartButton;
@property (weak, nonatomic) IBOutlet UITextView *statusText;
@property (weak, nonatomic) IBOutlet UITextField *heartRate;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UITextField *currentTimeField;
@property (weak, nonatomic) IBOutlet UITextField *totalTimeField;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *previousButton;
@property (nonatomic, strong) SPTSession *session;
@property (nonatomic, strong) SPTAudioStreamingController *player;
@property (nonatomic, weak) MSBClient *client;
@end

@implementation HomeViewController

NSString *clientId = @"ebd981eac8e34799b2dd48e6e20a802c";
NSString *callBackURL = @"musicon-login://callback";
CLLocationManager *locationManager;
NSTimer *timer;
NSTimer *songTimer;
NSTimeInterval currentTime;
NSTimeInterval totalTime;
NSUInteger lastRate = 0;
NSUInteger currentRate = 0;
float latitude = 0.0f;
float longitude = 0.0f;
BOOL bandConnected = NO;
BOOL replaceFlag = YES;

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    // Location Manager Set Up
    
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    [locationManager requestWhenInUseAuthorization];
    _progressBar.transform =CGAffineTransformScale(CGAffineTransformIdentity, 1, 3);
    
    _loginButton.hidden = true;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAfterFirstLogin) name:@"loginSuccessful" object:nil];
    
    // SetUp Microsoft Band
    [MSBClientManager sharedManager].delegate = self;
    NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
    self.client = [clients firstObject];
    if (self.client == nil)
    {
        [_statusText setText:@"Connection Failed"];
        return;
    }
    
    [[MSBClientManager sharedManager] connectClient:self.client];
    [_statusText setText:[NSString stringWithFormat:@"Connecting"]];
    
    // Spotify session loaded from userdefaults
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData* sessionData = (NSData *)[userDefaults objectForKey:@"SpotifySession"];
    
    if ([sessionData isKindOfClass:[NSData class]]) { //session available
        SPTSession* session = (SPTSession *)[NSKeyedUnarchiver unarchiveObjectWithData:sessionData];
        
        if (![session isValid]) {
            [[SPTAuth defaultInstance] renewSession:session callback:^(NSError *error, SPTSession *renewedSession) {
                if (error == nil) {
                    NSData *sessionData = [NSKeyedArchiver archivedDataWithRootObject:renewedSession];
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults setObject:sessionData forKey:@"SpotifySession"];
                    [userDefaults synchronize];
                    self.session = renewedSession;
                    [self playUsingSession:renewedSession];
                }
                else {
                    NSLog(@"Error while refreshing session");
                }
            }];
        }
        else {
            self.session = session;
            [self playUsingSession:session];
        }
    }
    else {
        _loginButton.hidden = false;
    }
    
}

- (void)updateAfterFirstLogin {
    
    _loginButton.hidden = true;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:@"SpotifySession"] != nil) {
        NSData *sessionData = [userDefaults objectForKey:@"SpotifySession"];
        SPTSession *firstSession = [NSKeyedUnarchiver unarchiveObjectWithData:sessionData];
        self.session = firstSession;
        [self playUsingSession:firstSession];
    }
    
}

- (void)playUsingSession:(SPTSession *) session {
    
    // Create a new player if needed
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:clientId];
        self.player.playbackDelegate = self;
    }
    
    [self.player loginWithSession:session callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"*** Logging in got error: %@", error);
            return;
        }
        
        // Get Lat, Long Info
//        latitude = locationManager.location.coordinate.latitude;
//        NSString *latString = [[NSNumber numberWithFloat:latitude] stringValue];
//        longitude = locationManager.location.coordinate.longitude;
//        NSString *longString = [[NSNumber numberWithFloat:longitude] stringValue];
        
        // Generated Request
//        NSString *stringURL = @"http://52.37.58.111/v1/user/fetch_rec/bverma"; // POST Request
//        NSArray *features = @[@"mood", @"location", @"weather", @"event",@"lat",@"lon"];
//        NSArray *feature_val = @[@"sad",@"gym",@"sunny", @"driving",latString,longString];
//        NSString *featureString = [NSString stringWithFormat: @"%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@",features[0],feature_val[0],features[1],feature_val[1],features[2],feature_val[2],features[3],feature_val[3],features[4],feature_val[4],features[5],feature_val[5]];
        
//        NSArray *songStringArr = [self sendNSURLRequest:stringURL withType:@"POST" andFeatureString:featureString];
        NSArray *songStringArr = [NSArray arrayWithObjects:@"spotify:track:3RiPr603aXAoi4GHyXx0uy",
                                  @"spotify:track:0BF6mdNROWgYo3O3mNGrBc",
                                  @"spotify:track:4O0Yww5OIWyfBvWn6xN3CM",
                                  @"spotify:track:3LlAyCYU26dvFZBDUIMb7a",
                                  @"spotify:track:0YuH7QCFXK0elodziM1cOU",
                                  nil];
        
        // spotify:track:3RiPr603aXAoi4GHyXx0uy - Hymn for the weekend
        // spotify:track:0BF6mdNROWgYo3O3mNGrBc - LeanOn
        // spotify:track:4O0Yww5OIWyfBvWn6xN3CM - Divenire
        // spotify:track:3LlAyCYU26dvFZBDUIMb7a - Demons
        // spotify:track:0YuH7QCFXK0elodziM1cOU - Saadi Gali
        
        NSMutableArray *songURIArr = [[NSMutableArray alloc] initWithCapacity:[songStringArr count]];
        
        for (NSString* uriString in songStringArr)
        {
            NSURL *songURL = [NSURL URLWithString:uriString];
            [songURIArr addObject:songURL];
        }
        
        [self.player playURIs:songURIArr fromIndex:0 callback:^(NSError *error) {
            if (error != nil) {
                NSLog(@"*** Starting playback got error: %@", error);
                return;
            }
        }];
    }];
    
}

- (void)updateCoverArt {
    
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    if ([self.player currentTrackMetadata] == nil){
        self.artworkImage.image = [UIImage imageNamed:@""];
        return;
    }
    
    NSString *uri = [self.player currentTrackMetadata][SPTAudioStreamingMetadataAlbumURI];
    [SPTAlbum albumWithURI:[NSURL URLWithString:uri] session:self.session callback:^(NSError *error, id object) {
        SPTAlbum *album = (SPTAlbum *) object;
        NSURL *url = [[album largestCover] imageURL];
        if (url != nil) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSError *error = nil;
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:url options:0 error:&error];
                UIImage *coverImage;
                
                if (error == nil) {
                    coverImage = [[UIImage alloc] initWithData:imageData];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.backgroundImage.hidden = true;
                    self.artworkImage.hidden = false;
                    self.artworkImage.image = coverImage;
                });
            });
        }
    }];
    
}

#pragma mark IBActions

- (IBAction)previousButtonPressed:(id)sender {
    [self.player skipPrevious:^(NSError *error) {
        if (error!=nil) {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            return;
        }
    }];
}

- (IBAction)actionButtonPressed:(id)sender {
    if ([self.player isPlaying]) {
        // Change pauseicon to playicon
        UIImage *playIcon = [UIImage imageNamed:@"PlayIcon"];
        [_actionButton setBackgroundImage:playIcon forState:UIControlStateNormal];
        
        // Stop Playing Song
        [self.player setIsPlaying:NO callback:^(NSError *error) {
            if (error!=nil) {
                NSLog(@"Error: %@ %@", error, [error userInfo]);
                return;
            }
        }];
        
        // Stop ProgressBar
        [timer invalidate];
    }
    else {
        // Change playicon to pauseicon
        UIImage *pauseIcon = [UIImage imageNamed:@"PauseIcon"];
        [_actionButton setBackgroundImage:pauseIcon forState:UIControlStateNormal];
        
        // Start Playing Song
        [self.player setIsPlaying:YES callback:^(NSError *error) {
            if (error!=nil) {
                NSLog(@"Error: %@ %@", error, [error userInfo]);
                return;
            }
        }];
        
        // Start ProgressBar
        timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressBar) userInfo:nil repeats:YES];
    }
}

- (IBAction)nextButtonPressed:(id)sender {
    if (!bandConnected) {
        [self.player skipNext:^(NSError *error) {
            if (error!=nil) {
                NSLog(@"Error: %@ %@", error, [error userInfo]);
                return;
            }
        }];
    }
    else {
        // empty queue, fetch new songs and play those songs
        if (lastRate == 0) {
            [self.player skipNext:^(NSError *error) {
                if (error!=nil) {
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                    return;
                }
                lastRate = currentRate;
            }];
        }
        else {
            if (replaceFlag) {
                replaceFlag = NO;
                songTimer = [NSTimer scheduledTimerWithTimeInterval:45.0 target:self selector:@selector(updateFlag) userInfo:nil repeats:NO];
                if (lastRate < 72 && currentRate >= 72)
                    [self replaceURI:currentRate];
                else if ((72 < lastRate && lastRate <= 77) && (77 < currentRate || currentRate <= 72))
                    [self replaceURI:currentRate];
                else if ((77 < lastRate && lastRate <= 90) && (90 < currentRate || currentRate <= 77))
                    [self replaceURI:currentRate];
                else if (lastRate > 90 && currentRate <= 90)
                    [self replaceURI:currentRate];
                else {
                    [self.player skipNext:^(NSError *error) {
                        if (error!=nil) {
                            NSLog(@"Error: %@ %@", error, [error userInfo]);
                            return;
                        }
                        lastRate = currentRate;
                    }];
                }
            }
            else {
                [self.player skipNext:^(NSError *error) {
                    if (error!=nil) {
                        NSLog(@"Error: %@ %@", error, [error userInfo]);
                        return;
                    }
                    lastRate = currentRate;
                }];
            }
        }
    }
}

- (IBAction)loginWithSpotify:(id)sender {
    // Override point for customization after application launch.
    [[SPTAuth defaultInstance] setClientID:clientId];
    [[SPTAuth defaultInstance] setRedirectURL:[NSURL URLWithString:callBackURL]];
    [[SPTAuth defaultInstance] setRequestedScopes:@[SPTAuthStreamingScope]];
    
    // Construct a login URL and open it
    NSURL *loginURL = [[SPTAuth defaultInstance] loginURL];
    
    // Opening a URL in Safari close to application launch may trigger an iOS bug, so we wait a bit before doing so.
    [[UIApplication sharedApplication] performSelector:@selector(openURL:)
                                            withObject:loginURL afterDelay:0.1];
    
}

- (IBAction)didTapHeart:(id)sender {
    if ([self.client.sensorManager heartRateUserConsent] == MSBUserConsentGranted)
    {
        [self startHearRateUpdates];
    }
    else
    {
        [_statusText setText:@"Requesting consent"];
        __weak typeof(self) weakSelf = self;
        [self.client.sensorManager requestHRUserConsentWithCompletion:^(BOOL userConsent, NSError *error) {
            if (userConsent)
            {
                [weakSelf startHearRateUpdates];
            }
            else
            {
                weakSelf.statusText.text = @"Consent declined";
            }
        }];
    }
}



#pragma mark Audio Delegate Implementations

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStartPlayingTrack:(NSURL *)trackUri {
    
    [_progressBar setHidden:NO];
    [_currentTimeField setHidden:NO];
    [_totalTimeField setHidden:NO];
    [_actionButton setHidden:NO];
    [_circleButton setHidden:NO];
    [_nextButton setHidden:NO];
    [_previousButton setHidden:NO];
    [_heartButton setHidden:NO];
    [_statusText setHidden:NO];
    
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressBar) userInfo:nil repeats:YES];
    [self updateProgressBar];
    [self updateCoverArt];
    
    UIImage *pauseIcon = [UIImage imageNamed:@"PauseIcon"];
    [_actionButton setBackgroundImage:pauseIcon forState:UIControlStateNormal];
}

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStopPlayingTrack:(NSURL *)trackUri {
    [timer invalidate];
    [self updateProgressBar];
    UIImage *playIcon = [UIImage imageNamed:@"PlayIcon"];
    [_actionButton setBackgroundImage:playIcon forState:UIControlStateNormal];
}

#pragma mark Location Delegate Implementations

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation* loc = [locations lastObject]; // locations is guaranteed to have at least one object
    latitude = loc.coordinate.latitude;
    longitude = loc.coordinate.longitude;
}

#pragma mark - MSBClientManagerDelegate

- (void)clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client
{
    [_statusText setText:[NSString stringWithFormat:@"Connected"]];
    [self startHearRateUpdates];
    bandConnected = YES;
}

- (void)clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client
{
    [_statusText setText:[NSString stringWithFormat:@"Disconnected"]];
    bandConnected = NO;
}

- (void)clientManager:(MSBClientManager *)clientManager client:(MSBClient *)client didFailToConnectWithError:(NSError *)error
{
    [_statusText setText:[NSString stringWithFormat:@"Failed to connect"]];
    bandConnected = NO;
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return NO;
}

#pragma mark Utilities

- (void)startHearRateUpdates
{
    [_statusText setText:@"Connected"];
    bandConnected = YES;
    
    __weak typeof(self) weakSelf = self;
    void (^handler)(MSBSensorHeartRateData *, NSError *) = ^(MSBSensorHeartRateData *heartRateData, NSError *error) {
        weakSelf.heartRate.hidden = NO;
        weakSelf.heartRate.text = [NSString stringWithFormat:@"%3u", (unsigned int)heartRateData.heartRate];
        currentRate = heartRateData.heartRate;
    };
    
    NSError *stateError;
    if (![self.client.sensorManager startHeartRateUpdatesToQueue:nil errorRef:&stateError withHandler:handler])
    {
        return;
    }
    
}

- (void) replaceURI:(NSUInteger)heartRate {
    
    NSLog(@"Replacing URIs");
    
    // Get Lat, Long Info
    latitude = locationManager.location.coordinate.latitude;
    NSString *latString = [[NSNumber numberWithFloat:latitude] stringValue];
    longitude = locationManager.location.coordinate.longitude;
    NSString *longString = [[NSNumber numberWithFloat:longitude] stringValue];
    NSString *rateString = [NSString stringWithFormat:@"%zd",heartRate];

    
    // Generate Request
    NSString *stringURL = @"http://52.37.58.111/v1/user/fetch_rec/bverma"; // POST Request
    NSArray *features = @[@"lat",@"lon",@"bmp"];
    NSArray *feature_val = @[latString,longString,rateString];
    NSString *featureString = [NSString stringWithFormat: @"%@=%@&%@=%@&%@=%@",features[0],feature_val[0],features[1],feature_val[1],features[2],feature_val[2]];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [hud setLabelText:@"Fetching Songs"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *songStringArr = [self sendNSURLRequest:stringURL withType:@"POST" andFeatureString:featureString];
        
        NSMutableArray *songURIArr = [[NSMutableArray alloc] initWithCapacity:[songStringArr count]];
        
        for (NSString* uriString in songStringArr)
        {
            NSURL *songURL = [NSURL URLWithString:uriString];
            [songURIArr addObject:songURL];
        }
        
        if ([songStringArr count] == 0) {
            NSArray *songArr = [NSArray arrayWithObjects:@"spotify:track:3w3y8KPTfNeOKPiqUTakBh",
                                      @"spotify:track:5A6OHHy73AR5tLxgTc98zz",
                                      @"spotify:track:5rC5JfViMoaZlDzTXc3tbY",
                                      @"spotify:track:3GpbwCm3YxiWDvy29Uo3vP",
                                      @"spotify:track:0O45fw2L5vsWpdsOdXwNAR",
                                      nil];
            
            // spotify:track:3w3y8KPTfNeOKPiqUTakBh - Locked out of heaven
            // spotify:track:5A6OHHy73AR5tLxgTc98zz - Black and Yellow
            // spotify:track:5rC5JfViMoaZlDzTXc3tbY - London Thumakda
            // spotify:track:3GpbwCm3YxiWDvy29Uo3vP - Right Round
            // spotify:track:0O45fw2L5vsWpdsOdXwNAR - Sexy Back
            
            NSMutableArray *uriArr = [[NSMutableArray alloc] initWithCapacity:[songArr count]];
            
            for (NSString* uriString in songArr)
            {
                NSURL *songURL = [NSURL URLWithString:uriString];
                [uriArr addObject:songURL];
            }
            
            [self.player replaceURIs:uriArr withCurrentTrack:-1 callback:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:NO];
                });
                
                if (error != nil) {
                    NSLog(@"*** Replacing URI got error: %@", error);
                    return;
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.player setIsPlaying:YES callback:^(NSError *error) {
                            if (error!=nil) {
                                NSLog(@"Error: %@ %@", error, [error userInfo]);
                                return;
                            }
                        }];
                    });
                }
            }];
        }
        else {
            int currentIndex = self.player.currentTrackIndex;
    
            [self.player replaceURIs:songURIArr withCurrentTrack:currentIndex callback:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:NO];
                });
                
                if (error != nil) {
                    NSLog(@"*** Replacing URI got error: %@", error);
                    return;
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.player setIsPlaying:YES callback:^(NSError *error) {
                            if (error!=nil) {
                                NSLog(@"Error: %@ %@", error, [error userInfo]);
                                return;
                            }
                        }];
                    });
                }
            }];
        }
        
        lastRate = heartRate;
    });
    
}

-(NSString *)getTime:(NSTimeInterval)time {
    int minutes = time/60;
    int seconds = time - (minutes*60);
    NSString *minString = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%d",minutes]];
    NSString *secString = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%d",seconds]];
    NSString *durationString = [[NSString alloc] init];
    if (seconds < 10)
        durationString = [NSString stringWithFormat: @"%@:0%@", minString, secString];
    else
        durationString = [NSString stringWithFormat: @"%@:%@", minString, secString];
    return durationString;
}

-(void)updateFlag {
    replaceFlag = YES;
}

-(void)updateProgressBar {
    currentTime = [self.player currentPlaybackPosition];
    totalTime = [self.player currentTrackDuration];
    [_progressBar setProgress:currentTime/totalTime];
    [_currentTimeField setText:[self getTime:currentTime]];
    [_totalTimeField setText:[self getTime:totalTime]];
}

-(NSArray *) sendNSURLRequest:(NSString *)stringURL withType:(NSString *)requestType andFeatureString:(NSString *)featureString {
    NSString *post =featureString;
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:stringURL]];
    [request setHTTPMethod:requestType];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSError *error;
    NSURLResponse *response;
    NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSMutableDictionary *dict = [NSJSONSerialization JSONObjectWithData:urlData options:NSJSONReadingMutableContainers error:nil];
    NSArray *songArr = [dict objectForKey:@"uris"];
    return songArr;
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
