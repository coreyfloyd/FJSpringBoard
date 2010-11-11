#import <Foundation/Foundation.h>

//uncomment if using the simulator with charles
#define USE_CHARLES_PROXY


//structs
typedef struct {
    NSUInteger complete;
    NSUInteger total;
    double ratio;
} Progress;

Progress progressWithIntegers(NSUInteger complete, NSUInteger total);
extern Progress const kProgressZero;

float nanosecondsWithSeconds(float seconds);

NSUInteger sizeOfFolderContentsInBytes(NSString* folderPath);
double megaBytesWithBytes(NSUInteger bytes);
double megaBytesWithLongBytes(long long bytes);


NSString* documentsDirectoryPath();