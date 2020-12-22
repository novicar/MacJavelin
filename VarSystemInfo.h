//
//  VarSystemInfo.h
//  Javelin
//
//  Created by harry on 22/08/2013.
//
//

#import <Foundation/Foundation.h>

@interface VarSystemInfo : NSObject
{
	NSString* sysName;
	NSString* sysUserName;
	NSString* sysFullUserName;
	NSString* sysOSName;
	NSString* sysOSVersion;
	NSString* sysPhysicalMemory;
	NSString* sysSerialNumber;
	NSString* sysUUID;
	NSString* sysModelID;
	NSString* sysModelName;
	NSString* sysProcessorName;
	NSString* sysProcessorSpeed;
	NSNumber* sysProcessorCount;
	NSString* getOSVersionInfo;
}

@property (readwrite, strong, nonatomic) NSString *sysName;
@property (readwrite, strong, nonatomic) NSString *sysUserName;
@property (readwrite, strong, nonatomic) NSString *sysFullUserName;
@property (readwrite, strong, nonatomic) NSString *sysOSName;
@property (readwrite, strong, nonatomic) NSString *sysOSVersion;
@property (readwrite, strong, nonatomic) NSString *sysPhysicalMemory;
@property (readwrite, strong, nonatomic) NSString *sysSerialNumber;
@property (readwrite, strong, nonatomic) NSString *sysUUID;
@property (readwrite, strong, nonatomic) NSString *sysModelID;
@property (readwrite, strong, nonatomic) NSString *sysModelName;
@property (readwrite, strong, nonatomic) NSString *sysProcessorName;
@property (readwrite, strong, nonatomic) NSString *sysProcessorSpeed;
@property (readwrite, strong, nonatomic) NSNumber *sysProcessorCount;
@property (readonly,  strong, nonatomic) NSString *getOSVersionInfo;

- (NSString *) _strIORegistryEntry:(NSString *)registryKey;
- (NSString *) _strControlEntry:(NSString *)ctlKey;
- (NSNumber *) _numControlEntry:(NSString *)ctlKey;
- (NSString *) _modelNameFromID:(NSString *)modelID;
- (NSString *) _parseBrandName:(NSString *)brandName;

@end
