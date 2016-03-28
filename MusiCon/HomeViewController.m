//
//  HomeViewController.m
//  MusiCon
//
//  Created by Bhanu Verma on 3/27/16.
//  Copyright © 2016 theRecommendables. All rights reserved.
//

#import "HomeViewController.h"

@interface HomeViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIImageView *artworkImage;
@property (nonatomic, strong) SPTSession *session;
@property (nonatomic, strong) SPTAudioStreamingController *player;
@end

@implementation HomeViewController

NSString * clientId = @"ebd981eac8e34799b2dd48e6e20a802c";
NSString * callBackURL = @"musicon-login://callback";

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    _loginButton.hidden = true;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAfterFirstLogin) name:@"loginSuccessfull" object:nil];
    
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
        
    // spotify:track:0BF6mdNROWgYo3O3mNGrBc - LeanOn
        NSURL *trackURI = [NSURL URLWithString:@"spotify:track:0BF6mdNROWgYo3O3mNGrBc"];
        [self.player playURIs:@[trackURI] fromIndex:0 callback:^(NSError *error) {
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
                    self.artworkImage.image = coverImage;
                });
            });
        }
    }];
    
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

-(void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didStartPlayingTrack:(NSURL *)trackUri {
    [self updateCoverArt];
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
