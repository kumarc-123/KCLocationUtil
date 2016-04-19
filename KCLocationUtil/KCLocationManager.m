//
//  KCLocationManager.m
//  KCLocationUtil
//
//  Created by Kumar C on 4/19/16.
//  Copyright © 2016 Kumar C. All rights reserved.
//

#import "KCLocationManager.h"

@interface KCLocationManager () <CLLocationManagerDelegate>
{
    CLLocationCoordinate2D noLocation;
}

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) KCLocationHandler handler;

@property (atomic, readwrite) BOOL hasSentUpdatedLocation;

@property (nonatomic, copy, readwrite) NSString *applicationName;

@end


@implementation KCLocationManager

+ (instancetype) sharedManager
{
    static KCLocationManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (instancetype) withAppName:(NSString *)applicationName
{
    KCLocationManager *locationManager = [KCLocationManager sharedManager];
    [locationManager setApplicationName:applicationName];
    return locationManager;
}

- (id) init
{
    self = [super init];
    if (self) {
        _locationManager = [CLLocationManager new];
        [_locationManager setDelegate:self];
        
        noLocation = CLLocationCoordinate2DMake(0, 0);
        
        _userLocation = noLocation;
    }
    return self;
}

- (void) getCurrentLocationWithCompletion:(KCLocationHandler)completion
{
    if([[[[NSBundle mainBundle] infoDictionary] valueForKey:@"ShouldUseSimulatedLocation"] boolValue])
    {
        CLLocationCoordinate2D from = CLLocationCoordinate2DMake(41.258108, -95.93504);
        CLLocationCoordinate2D to = CLLocationCoordinate2DMake(40.759211000000001, -73.984638000000003);
        
        _userLocation = to;
        
        completion (YES, from, to, nil);
    }
    else
    {
        _handler = [completion copy];
        _hasSentUpdatedLocation = NO;
        if (![CLLocationManager locationServicesEnabled]) {
            [self sendLocationWithSuccess:NO fromLocation:noLocation toLocation:noLocation withError:@"Location service is disabled. Please go to Settings-> Privacy-> Location."];
            return;
        }
        
        CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
        switch (authStatus) {
            case kCLAuthorizationStatusAuthorizedAlways:
            case kCLAuthorizationStatusAuthorizedWhenInUse:
            {
                [_locationManager startUpdatingLocation];
            }
                break;
            case kCLAuthorizationStatusNotDetermined:
            {
                if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                    [_locationManager requestWhenInUseAuthorization];
                }
            }
                break;
            case kCLAuthorizationStatusDenied:
            {
                NSString *message = [NSString stringWithFormat:@"Location service is disabled for %@. Please go to Settings-> %@-> Location Services and set it to When In Use or Always", _applicationName, _applicationName];
                [self sendLocationWithSuccess:NO fromLocation:noLocation toLocation:noLocation withError:message];
                return;
                
            }
            case kCLAuthorizationStatusRestricted:
            {
                [self sendLocationWithSuccess:NO fromLocation:noLocation toLocation:noLocation withError:@"Location service is restricted. Please go to Settings-> General-> Restrictions-> Location Services to disable restrictions."];
                return;
            }
                
            default:
                break;
        }
    }
}

#pragma mark - CLLocation Manager Delegates

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            if ([CLLocationManager locationServicesEnabled]) {
                if (!_hasSentUpdatedLocation) {
                    [_locationManager startUpdatingLocation];
                }
            }
            else if (!_hasSentUpdatedLocation)
            {
                [self sendLocationWithSuccess:NO fromLocation:noLocation toLocation:noLocation withError:@"Location service is disabled. Please go to Settings->Privacy--Location."];
            }
            break;
        case kCLAuthorizationStatusDenied:
        {
            NSLog(@"Location service for this app is denied.");
        }
            break;
        case kCLAuthorizationStatusNotDetermined:
        {
            NSLog(@"User has not set any location preferences for this app.");
        }
            break;
        case kCLAuthorizationStatusRestricted:
        {
            NSLog(@"Location services are restricted for this app.");
        }
            
        default:
            break;
    }
}

- (void) reverseGeocode : (CLLocationCoordinate2D) location2D completion : (KCGeoCodeHandler) complation
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:location2D.latitude longitude:location2D.longitude];
    
    CLGeocoder *geoCoder = [CLGeocoder new];
    
    [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (error == nil && [placemarks count] > 0)
         {
             complation (YES, [placemarks lastObject], nil);
         }
         else
         {
             complation (NO, nil, [self getErrorMessageForMKError:[error code]]);
         }
     }];
}

- (void) reverseGeocodeUserLocation:(KCGeoCodeHandler)complation
{
    [self reverseGeocode:_userLocation completion:complation];
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (!_hasSentUpdatedLocation && _handler != NULL)
    {
        if (![CLLocationManager locationServicesEnabled])
        {
            [self sendLocationWithSuccess:NO fromLocation:noLocation toLocation:noLocation withError:@"Location service is disabled. Please go to Settings-> Privacy-> Location."];
            return;
        }
        
        
        CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
        switch (authStatus) {
            case kCLAuthorizationStatusDenied:
            {
                NSString *message = [NSString stringWithFormat:@"Location service is disabled for %@. Please go to Settings-> %@-> Location Services and set it to When In Use or Always", _applicationName, _applicationName];
                [self sendLocationWithSuccess:NO fromLocation:noLocation toLocation:noLocation withError:message];
                return;
                
            }
            case kCLAuthorizationStatusRestricted:
            {
                [self sendLocationWithSuccess:NO fromLocation:noLocation toLocation:noLocation withError:@"Location service is restricted. Please go to Settings-> General-> Restrictions-> Location Services to disable restrictions."];
                return;
            }
                
            default:
                break;
        }
        
        [self sendLocationWithSuccess:NO fromLocation:noLocation toLocation:noLocation withError:[self getErrorMessageForError:[error code]]];
    }
}

- (NSString *) getErrorMessageForError:(CLError)errorCode
{
    NSString *errorMessage = @"Unable to obtain location services at this time. Please try again.";
    
    switch (errorCode) {
        case kCLErrorDeferredAccuracyTooLow:
            errorMessage = @"Deferred mode is not supported for the requested accuracy.";
            break;
        case kCLErrorDeferredCanceled:
            errorMessage = @"The request for deferred updates was canceled by the app or by the location manager.";
            break;
        case kCLErrorDeferredDistanceFiltered:
            errorMessage = @"Deferred mode does not support distance filters.";
            break;
        case kCLErrorDeferredFailed:
            errorMessage = @"GPS is unavailable, not active, or is temporarily interrupted.";
            break;
        case kCLErrorDeferredNotUpdatingLocation:
            errorMessage = @"Location updates were disabled or paused. Plese try again.";
            break;
        case kCLErrorDenied:
            errorMessage = @"Location service is disabled for this app. Please go to app settings and enable location service.";
            break;
        case kCLErrorGeocodeCanceled:
            errorMessage = @"The geocode request was canceled.";
            break;
        case kCLErrorGeocodeFoundNoResult:
            errorMessage = @"The geocode request yielded no result. Please try with a different keyword.";
            break;
        case kCLErrorGeocodeFoundPartialResult:
            errorMessage = @"The geocode request yielded a partial result. Please try with a different keyword.";
            break;
        case kCLErrorHeadingFailure:
            errorMessage = @"The heading could not be determined. Please try again.";
            break;
        case kCLErrorLocationUnknown:
            errorMessage = @"Unable to obtain a location value right now. Please try again.";
            break;
        case kCLErrorNetwork:
            errorMessage = @"The network was unavailable or a network error occurred. Please try again.";
            break;
        case kCLErrorRangingFailure:
            errorMessage = @"A general ranging error occurred. Please try again.";
            break;
        case kCLErrorRangingUnavailable:
            errorMessage = @"Ranging is disabled. This might happen if your device is in Airplane mode or if Bluetooth or location services are disabled.";
            break;
        case kCLErrorRegionMonitoringDenied:
            errorMessage = @"Access to the region monitoring service was denied by the user.";
            break;
        case kCLErrorRegionMonitoringFailure:
            errorMessage = @"A registered region cannot be monitored or the region’s radius distance is too large.";
            break;
        case kCLErrorRegionMonitoringResponseDelayed:
            errorMessage = @"Unable to obtain a location value right now. Please try again.";
            break;
        case kCLErrorRegionMonitoringSetupDelayed:
            errorMessage = @"Could not initialize the region monitoring feature immediately. Please try again.";
            break;
            
        default:
            break;
    }
    return errorMessage;
}

- (NSString *) getErrorMessageForMKError:(MKErrorCode)errorCode
{
    NSString *errorMessage = @"Unable to obtain map services at this time. Please try again.";
    
    switch (errorCode) {
        case MKErrorUnknown:
            errorMessage = @"An unknown error occurred. Please try again.";
            break;
        case MKErrorServerFailure:
            errorMessage = @"The map server was unable to return the desired information. Please try again.";
            break;
        case MKErrorLoadingThrottled:
            errorMessage = @"The data was not loaded because data throttling is in effect. Please try again.";
            break;
        case MKErrorPlacemarkNotFound:
            errorMessage = @"The search did not yield any results. Please make sure the search info is correct, or try with a different search info.";
            break;
        case MKErrorDirectionsNotFound:
            errorMessage = @"The specified directions could not be found.";
            break;
        default:
            break;
    }
    return errorMessage;
}

- (void) sendLocationWithSuccess : (BOOL) success fromLocation : (CLLocationCoordinate2D) fromLocation toLocation : (CLLocationCoordinate2D) toLocation withError : (NSString *) errorMessage
{
    if (!_hasSentUpdatedLocation && _handler != NULL)
    {
        _userLocation = toLocation;
        _hasSentUpdatedLocation = YES;
        _handler (success, fromLocation, toLocation, errorMessage);
        _handler = NULL;
    }
    [_locationManager stopUpdatingLocation];
}

- (CLLocationDistance) distanceFromCurrentLocationToLocation2D : (CLLocationCoordinate2D) toLocation2D
{
    CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:_userLocation.latitude longitude:_userLocation.longitude];
    CLLocation *toLocation = [[CLLocation alloc] initWithLatitude:toLocation2D.latitude longitude:toLocation2D.longitude];
    return [fromLocation distanceFromLocation:toLocation];
}

- (CLLocationDistance) distanceFromLocation2D : (CLLocationCoordinate2D) fromLocation2D toLocation2D : (CLLocationCoordinate2D) toLocation2D
{
    CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:fromLocation2D.latitude longitude:fromLocation2D.longitude];
    CLLocation *toLocation = [[CLLocation alloc] initWithLatitude:toLocation2D.latitude longitude:toLocation2D.longitude];
    return [fromLocation distanceFromLocation:toLocation];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [self sendLocationWithSuccess:YES fromLocation:[oldLocation coordinate] toLocation:[newLocation coordinate] withError:nil];
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [self sendLocationWithSuccess:YES fromLocation:[[locations firstObject] coordinate] toLocation:[[locations lastObject] coordinate] withError:nil];
}

@end
