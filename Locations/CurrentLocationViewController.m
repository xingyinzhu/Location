//
//  FirstViewController.m
//  Locations
//
//  Created by Xingyin Zhu on 12-12-3.
//  Copyright (c) 2012年 Xingyin Zhu. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>
#import <QuartzCore/QuartzCore.h>
#import "CurrentLocationViewController.h"
#import "LocationDetailsViewController.h"
#import "NSMutableString+AddText.h"

@interface CurrentLocationViewController ()

@end

@implementation CurrentLocationViewController
{
    CLLocationManager *locationManager;
    CLLocation *location;
    BOOL updatingLocation;
    NSError *lastLocationError;
    
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
    BOOL performingReverseGeocoding;
    NSError *lastGeocodingError;
    
    UIActivityIndicatorView *spinner;
    SystemSoundID soundID;
    UIImageView *logoImageView;
    BOOL firstTime;
}

@synthesize managedObjectContext;

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TagLocation"])
    {
        UINavigationController *navigationController = segue.destinationViewController;
        LocationDetailsViewController *controller = (LocationDetailsViewController *)navigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
        controller.coordinate = location.coordinate;
        controller.placemark = placemark;
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        locationManager = [[CLLocationManager alloc] init];
        geocoder = [[CLGeocoder alloc] init];
        firstTime = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self updateLabels];
    [self configureGetButton];
    [self loadSoundEffect];
    
    if (firstTime)
    {
        [self showLogoView];
    }
    else
    {
        [self hideLogoViewAnimated:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)getLocation:(id)sender
{
    if (firstTime)
    {
        firstTime = NO;
        [self hideLogoViewAnimated:YES];
    }
    
    if (updatingLocation)
    {
        [self stopLocationManager];
    }
    else
    {
        location = nil;
        lastLocationError = nil;
        placemark = nil;
        lastGeocodingError = nil;
        
        [self startLocationManager];
    }
    
    [self updateLabels];
    [self configureGetButton];
}

#pragma mark - CLLocationManagerDelegate
- (void)stopLocationManager
{
    if (updatingLocation)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(didTimeOut:) object:nil];
        [locationManager stopUpdatingLocation];
        locationManager.delegate = nil;
        updatingLocation = NO;
    }
}

- (void)didTimeOut:(id)obj
{
    NSLog(@"*** Time out");
    if (location == nil)
    {
        [self stopLocationManager];
        lastLocationError = [NSError errorWithDomain:@"MyLocationsErrorDomain" code:1 userInfo:nil];
        [self updateLabels];
        [self configureGetButton];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError %@", error);
    if (error.code == kCLErrorLocationUnknown)
    {
        return;
    }
    
    [self stopLocationManager];
    lastLocationError = error;
    [self updateLabels];
    [self configureGetButton];
    
}

- (void)startLocationManager
{
    if ([CLLocationManager locationServicesEnabled])
    {
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [locationManager startUpdatingLocation];
        updatingLocation = YES;
        
        [self performSelector:@selector(didTimeOut:) withObject:nil afterDelay:60];
    }
}


- (NSString *)stringFromPlacemark:(CLPlacemark *)thePlacemark
{
    NSMutableString *line1 = [NSMutableString stringWithCapacity:100];
    
    [line1 addText:thePlacemark.subThoroughfare withSeparator:@""];
    [line1 addText:thePlacemark.thoroughfare withSeparator:@" "];
    
    NSMutableString *line2 = [NSMutableString stringWithCapacity:100];
    
    [line2 addText:thePlacemark.locality withSeparator:@""];
    [line2 addText:thePlacemark.administrativeArea withSeparator:@" "];
    [line2 addText:thePlacemark.postalCode withSeparator:@" "];
    
    if ([line1 length] == 0)
    {
        [line2 appendString:@"\n "];
        return line2;
    }
    else
    {
        [line1 appendString:@"\n"];
        [line1 appendString:line2];
        return line1;
    }
    /*
    return [NSString stringWithFormat:@"%@ %@\n%@ %@ %@",
            thePlacemark.subThoroughfare,
            thePlacemark.thoroughfare,
            thePlacemark.locality,
            thePlacemark.administrativeArea,
            thePlacemark.postalCode];
     */
}

- (void)updateLabels
{
    if (location != nil)
    {
        self.messageLabel.text = @"GPS Coordinates";
        self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", location.coordinate.latitude];
        self.longitudeLabel.text = [NSString stringWithFormat:@"%.8f", location.coordinate.longitude];
        self.tagButton.hidden = NO;
        self.latitudeTextLabel.hidden = NO;
        self.longitudeTextLabel.hidden = NO;
        
        if (placemark != nil)
        {
            self.addressLabel.text = [self stringFromPlacemark:placemark];
        }
        else if (performingReverseGeocoding)
        {
            self.addressLabel.text = @"Searching for Address...";
        }
        else if (lastGeocodingError != nil)
        {
            self.addressLabel.text = @"Error Finding Address";
        }
        else
        {
            self.addressLabel.text = @"No Address Found";
        }
    }
    else
    {
        //self.messageLabel.text = @"Press the Button to Start";
        self.latitudeLabel.text = @"";
        self.longitudeLabel.text = @"";
        self.addressLabel.text = @"";
        self.tagButton.hidden = YES;
        self.latitudeTextLabel.hidden = YES;
        self.longitudeTextLabel.hidden = YES;
        
        NSString *statusMessage;
        if (lastLocationError != nil)
        {
            if ([lastLocationError.domain isEqualToString:kCLErrorDomain] && lastLocationError.code == kCLErrorDenied)
            {
                statusMessage = @"Location Services Disabled";
            }
            else
            {
                statusMessage = @"Error Getting Location";
            }
        }
        else if (![CLLocationManager locationServicesEnabled])
        {
            statusMessage = @"Location Services Disabled";
        }
        else if (updatingLocation)
        {
            statusMessage = @"Searching...";
        }
        else
        {
            statusMessage = @"Press the Button to Start";
        }
        
        self.messageLabel.text = statusMessage;
    }
        
}

- (void)configureGetButton
{
    if (updatingLocation)
    {
        [self.getButton setTitle:@"Stop" forState:UIControlStateNormal];
        
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.center = CGPointMake(self.getButton.bounds.size.width - spinner.bounds.size.width/2.0f - 10, self.getButton.bounds.size.height / 2.0f);
        [spinner startAnimating];
        [self.getButton addSubview:spinner];
    }
    else
    {
        [self.getButton setTitle:@"Get My Location" forState:UIControlStateNormal];
        
        [spinner removeFromSuperview];
        spinner = nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //NSLog(@"didUpdateToLocation %@", newLocation);
    
    if ([newLocation.timestamp timeIntervalSinceNow] < -5.0)
    {
        return;
    }
    
    if (newLocation.horizontalAccuracy < 0)
    {
        return;
    }
    
    CLLocationDistance distance = MAXFLOAT;
    if (location != nil)
    {
        distance = [newLocation distanceFromLocation:location];
    }
    
    if (location == nil || location.horizontalAccuracy > newLocation.horizontalAccuracy)
    {
        lastLocationError = nil;
        location = newLocation;
        [self updateLabels];
        
        if (newLocation.horizontalAccuracy <= locationManager.desiredAccuracy)
        {
            NSLog(@"*** We're done!");
            [self stopLocationManager];
            [self configureGetButton];
            
            if (distance > 0)
            {
                performingReverseGeocoding = NO;
            }
        }
        
        
        if (!performingReverseGeocoding)
        {
            NSLog(@"*** Going to geocode");
            
            performingReverseGeocoding = YES;
            [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
                {
                    NSLog(@"*** Found placemarks: %@, error: %@", placemarks, error);
                    
                    lastGeocodingError = error;
                    if (error == nil && [placemarks count] > 0)
                    {
                        if (placemark == nil)
                        {
                            NSLog(@"FIRST TIME!");
                            [self playSoundEffect];
                        }
                        placemark = [placemarks lastObject];
                    }
                    else
                    {
                        placemarks = nil;
                        
                    }
                    performingReverseGeocoding = NO;
                    [self updateLabels];
                }
            ];
            
        }
        
    }
    else if (distance < 1.0)
    {
        NSTimeInterval timeInterval = [newLocation.timestamp timeIntervalSinceDate:location.timestamp];
        if (timeInterval > 10)
        {
            NSLog(@"*** Force done!");
            [self stopLocationManager];
            [self updateLabels];
            [self configureGetButton];
        }
    }
}

#pragma mark - Sound Effect
- (void)loadSoundEffect
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Sound.caf" ofType: nil];
    NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO]; if (fileURL == nil)
    {
        NSLog(@"NSURL is nil for path: %@", path);
        return;
    }
    
    OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileURL, &soundID);
    if (error != kAudioServicesNoError)
    {
        NSLog(@"Error code %ld loading sound at path: %@", error, path); return;
    }
}

- (void)unloadSoundEffect
{
    AudioServicesDisposeSystemSoundID(soundID);
    soundID = 0;
}

- (void)playSoundEffect
{
    AudioServicesPlaySystemSound(soundID);
}

#pragma mark - Logo View
- (void)showLogoView
{
    self.panelView.hidden = YES;
    logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo"]];
    logoImageView.center = CGPointMake(160.0f, 140.0f);
    [self.view addSubview:logoImageView];
}

- (void)hideLogoViewAnimated:(BOOL)animated
{
    self.panelView.hidden = NO;
    
    if (animated)
    {
        self.panelView.center = CGPointMake(600.0f, 120.0f);
        //self.panelView.center = CGPointMake(140.0f, 140.0f);
        
        
        CABasicAnimation *panelMover = [CABasicAnimation animationWithKeyPath:@"position"];
        panelMover.removedOnCompletion = NO;
        panelMover.fillMode = kCAFillModeForwards;
        panelMover.duration = 0.6f;
        panelMover.fromValue = [NSValue valueWithCGPoint:self.panelView.center];
        panelMover.toValue = [NSValue valueWithCGPoint:CGPointMake(140.0f, 120.0f)];//self.panelView.center.y)];
        panelMover.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        panelMover.delegate = self;
        [self.panelView.layer addAnimation:panelMover forKey:@"panelMover"];
        
        
        CABasicAnimation *logoMover = [CABasicAnimation animationWithKeyPath:@"position"];
        logoMover.removedOnCompletion = NO;
        logoMover.fillMode = kCAFillModeForwards;
        logoMover.duration = 0.5f;
        logoMover.fromValue = [NSValue valueWithCGPoint:logoImageView.center];
        logoMover.toValue = [NSValue valueWithCGPoint:CGPointMake(-160.0f, logoImageView.center.y)];
        logoMover.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [logoImageView.layer addAnimation:logoMover forKey:@"logoMover"];
        
        CABasicAnimation *logoRotator = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        logoRotator.removedOnCompletion = NO;
        logoRotator.fillMode = kCAFillModeForwards;
        logoRotator.duration = 0.5f;
        logoRotator.fromValue = [NSNumber numberWithFloat:0];
        logoRotator.toValue = [NSNumber numberWithFloat:-2*M_PI];
        logoRotator.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [logoImageView.layer addAnimation:logoRotator forKey:@"logoRotator"];
        
        
        
    }
    else
    {
        [logoImageView removeFromSuperview];
        logoImageView = nil;
    }
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self.panelView.layer removeAllAnimations];
    self.panelView.center = CGPointMake(140.0f, 120.0f);
    
    [logoImageView.layer removeAllAnimations];
    [logoImageView removeFromSuperview];
    logoImageView = nil;
}

@end
