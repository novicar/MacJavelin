//
//  VarSystemInfo.m
//  Javelin
//
//  Created by harry on 22/08/2013.
//
//

#import "VarSystemInfo.h"

static NSString* const kVarSysInfoVersionFormat  = @"%@.%@.%@ (%@)";
static NSString* const kVarSysInfoPlatformExpert = @"IOPlatformExpertDevice";

static NSString* const kVarSysInfoKeyOSVersion = @"kern.osrelease";
static NSString* const kVarSysInfoKeyOSBuild   = @"kern.osversion";
static NSString* const kVarSysInfoKeyModel     = @"hw.model";
static NSString* const kVarSysInfoKeyCPUCount  = @"hw.physicalcpu";
static NSString* const kVarSysInfoKeyCPUFreq   = @"hw.cpufrequency";
static NSString* const kVarSysInfoKeyCPUBrand  = @"machdep.cpu.brand_string";

static NSString* const kVarSysInfoMachineNames       = @"MachineNames";
static NSString* const kVarSysInfoMachineiMac        = @"iMac";
static NSString* const kVarSysInfoMachineMacmini     = @"Mac mini";
static NSString* const kVarSysInfoMachineMacBookAir  = @"MacBook Air";
static NSString* const kVarSysInfoMachineMacBookPro  = @"MacBook Pro";
static NSString* const kVarSysInfoMachineMacPro      = @"Mac Pro";

#pragma mark - Implementation:
#pragma mark -

@implementation VarSystemInfo

@synthesize sysName, sysUserName, sysFullUserName;
@synthesize sysOSName, sysOSVersion;
@synthesize sysPhysicalMemory;
@synthesize sysSerialNumber, sysUUID;
@synthesize sysModelID, sysModelName;
@synthesize sysProcessorName, sysProcessorSpeed, sysProcessorCount;

#pragma mark - Helper Methods:

- (NSString *) _strIORegistryEntry:(NSString *)registryKey {

    NSString *retString = nil;

    io_service_t service =
    IOServiceGetMatchingService( kIOMasterPortDefault,
                                 IOServiceMatching([kVarSysInfoPlatformExpert UTF8String]) );
    if ( service ) {

        CFTypeRef cfRefString =
        IORegistryEntryCreateCFProperty( service,
                                         (__bridge CFStringRef)registryKey,
                                         kCFAllocatorDefault, kNilOptions );
        if ( cfRefString ) {

            retString = [NSString stringWithString:(__bridge NSString *)cfRefString];
            CFRelease(cfRefString);

        } IOObjectRelease( service );

    } return retString;
}

- (NSString *) _strControlEntry:(NSString *)ctlKey {

 /*   size_t size = 0;
    if ( sysctlbyname([ctlKey UTF8String], NULL, &size, NULL, 0) == -1 ) return nil;

    char *machine = calloc( 1, size );

    sysctlbyname([ctlKey UTF8String], machine, &size, NULL, 0);
    NSString *ctlValue = [NSString stringWithCString:machine encoding:[NSString defaultCStringEncoding]];

    free(machine); return ctlValue;*/
	return @"";//20201222
}

- (NSNumber *) _numControlEntry:(NSString *)ctlKey {

/*    size_t size = sizeof( uint64_t ); uint64_t ctlValue = 0;
    if ( sysctlbyname([ctlKey UTF8String], &ctlValue, &size, NULL, 0) == -1 ) return nil;
    return [NSNumber numberWithUnsignedLongLong:ctlValue];*/
	
	return [NSNumber numberWithUnsignedLong:0];
}

- (NSString *) _modelNameFromID:(NSString *)modelID {

    /*!
     * @discussion Maintain Machine Names plist from the following site
     * @abstract ref: http://www.everymac.com/systems/by_capability/mac-specs-by-machine-model-machine-id.html
     *
     * @discussion Also info found in SPMachineTypes.plist @ /System/Library/PrivateFrameworks/...
     *             ...AppleSystemInfo.framework/Versions/A/Resources
     *             Information here is private and can not be linked into the code.
     */

/*    NSDictionary *modelDict = [[NSBundle mainBundle] URLForResource:kVarSysInfoMachineNames withExtension:@"plist"].serialPList;
    NSString *modelName = [modelDict objectForKey:modelID];

    if ( !modelName ) {

        if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineiMac.lowercaseString] ) return kVarSysInfoMachineiMac;
        else if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineMacmini.noWhitespaceAndLowerCaseString] )    return kVarSysInfoMachineMacmini;
        else if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineMacBookAir.noWhitespaceAndLowerCaseString] ) return kVarSysInfoMachineMacBookAir;
        else if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineMacBookPro.noWhitespaceAndLowerCaseString] ) return kVarSysInfoMachineMacBookPro;
        else if ( [modelID.lowercaseString hasPrefix:kVarSysInfoMachineMacPro.noWhitespaceAndLowerCaseString] )     return kVarSysInfoMachineMacPro;
        else return modelID;

    } return modelName;*/
	
	return @"";
}

- (NSString *) _parseBrandName:(NSString *)brandName {

    if ( !brandName ) return nil;

    NSMutableArray *newWords = [NSMutableArray array];
    NSString *strCopyRight = @"r", *strTradeMark = @"tm", *strCPU = @"CPU";

    NSArray *words = [brandName componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];

    for ( NSString *word in words ) {

        if ( [word isEqualToString:strCPU] )       break;
        if ( [word isEqualToString:@""] )          continue;
        if ( [word.lowercaseString isEqualToString:strCopyRight] ) continue;
        if ( [word.lowercaseString isEqualToString:strTradeMark] ) continue;

        if ( [word length] > 0 ) {

            NSString *firstChar = [word substringToIndex:1];
            if ( NSNotFound != [firstChar rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location ) continue;

            [newWords addObject:word];

    } } return [newWords componentsJoinedByString:@" "];
}

-(NSString*) getOSVersionInfo 
{
	return [[NSProcessInfo processInfo] operatingSystemVersionString];
}

- (NSString *) getOSVersionInfoOLD {

/*    NSString *darwinVer = [self _strControlEntry:kVarSysInfoKeyOSVersion];
    NSString *buildNo = [self _strControlEntry:kVarSysInfoKeyOSBuild];
    if ( !darwinVer || !buildNo ) return nil;

    NSString *majorVer = @"10", *minorVer = @"x", *bugFix = @"x";
    NSArray *darwinChunks = [darwinVer componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];

    if ( [darwinChunks count] > 0 ) {

        NSInteger firstChunk = [(NSString *)[darwinChunks objectAtIndex:0] integerValue];
        minorVer = [NSString stringWithFormat:@"%d", (firstChunk - 4)];
        bugFix = [darwinChunks objectAtIndex:1];
        return [NSString stringWithFormat:kVarSysInfoVersionFormat, majorVer, minorVer, bugFix, buildNo];

    } */return nil;
}

#pragma mark - Initalization:

- (void) setupSystemInformation {

    NSProcessInfo *pi = [NSProcessInfo processInfo];

    self.sysName = [[NSHost currentHost] localizedName];
    self.sysUserName = NSUserName();
    self.sysFullUserName = NSFullUserName();
	self.sysOSName = pi.operatingSystemVersionString;//pi.operatingSystemName;
    self.sysOSVersion = self.getOSVersionInfo;
    self.sysPhysicalMemory = [NSString stringWithFormat:@"%lld", pi.physicalMemory];
	
	//[[NSNumber numberWithUnsignedLongLong:pi.physicalMemory] strBinarySizeMaxFractionDigits:0];

    self.sysSerialNumber = [self _strIORegistryEntry:(NSString *)CFSTR(kIOPlatformSerialNumberKey)];
    self.sysUUID = [self _strIORegistryEntry:(NSString *)CFSTR(kIOPlatformUUIDKey)];
    //20201222 self.sysModelID = [self _strControlEntry:kVarSysInfoKeyModel];
    self.sysModelName = [self _modelNameFromID:self.sysModelID];
	//20201222 self.sysProcessorName = [self _parseBrandName:[self _strControlEntry:kVarSysInfoKeyCPUBrand]];
    self.sysProcessorSpeed =[NSString stringWithFormat:@"%@", [self _numControlEntry:kVarSysInfoKeyCPUFreq]];
	//[[self _numControlEntry:kVarSysInfoKeyCPUFreq] strBaseTenSpeedMaxFractionDigits:2];
    self.sysProcessorCount = [self _numControlEntry:kVarSysInfoKeyCPUCount];
}

- (id) init {

    if ( (self = [super init]) ) {

        [self setupSystemInformation];

    } return self;
}

@end

