//
//  KCLocationManager.h
//  KCLocationUtil
//
//  Created by Kumar C on 4/19/16.
//  Copyright © 2016 Kumar C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

typedef void (^KCLocationHandler) (BOOL success, CLLocationCoordinate2D fromLocation, CLLocationCoordinate2D toLocation, NSString * _Nullable errorMessage);

typedef void (^KCGeoCodeHandler) (BOOL success, CLPlacemark * _Nullable placemark , NSString * _Nullable errorMessage);

@interface KCLocationManager : NSObject

@property (nonatomic, assign, readonly) CLLocationCoordinate2D userLocation;

@property (nullable, nonatomic, copy, readonly) NSString *applicationName;

- (void) reverseGeocode : (CLLocationCoordinate2D) location2D completion : (nonnull KCGeoCodeHandler) complation;

- (void) reverseGeocodeUserLocation : (nonnull KCGeoCodeHandler) complation;

- (void) getCurrentLocationWithCompletion : (nonnull KCLocationHandler) completion;

- (CLLocationDistance) distanceFromCurrentLocationToLocation2D : (CLLocationCoordinate2D) toLocation2D;

- (CLLocationDistance) distanceFromLocation2D : (CLLocationCoordinate2D) fromLocation2D toLocation2D : (CLLocationCoordinate2D) toLocation2D;

+ (nonnull instancetype) sharedManager;

+ (nonnull instancetype) withAppName : (nonnull NSString *) applicationName;

- (nonnull NSString *) getErrorMessageForError : (CLError) errorCode;

- (nonnull NSString *) getErrorMessageForMKError : (MKErrorCode) errorCode;

@end
