//
//  PulseDetector.mm
//  HeartRate_Demo
//
//  Created by Transuner on 16/4/15.
//  Copyright © 2016年 吴冰. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PulseDetector.h"
#import <vector>
#import <algorithm>

#define MAX_PERIOD 1.5
#define MIN_PERIOD 0.1
#define INVALID_ENTRY -100

@implementation PulseDetector

@synthesize periodStart;


- (id) init
{
	self = [super init];
	if (self != nil) {
    // 从新设置
    [self reset];
	}
	return self;
}

-(void) reset {
	for(int i=0; i<MAX_PERIODS_TO_STORE; i++) {
		periods[i]=INVALID_ENTRY;
	}
	for(int i=0; i<AVERAGE_SIZE; i++) {
		upVals[i]=INVALID_ENTRY;
		downVals[i]=INVALID_ENTRY;
	}	
  freq=0.5;
  periodIndex=0;
  downValIndex=0;
  upValIndex=0;
}

-(float) addNewValue:(float) newVal atTime:(double) time {	
  // 我们跟踪的数量值高于和低于零
    
	if(newVal>0) {
		upVals[upValIndex]=newVal;
		upValIndex++;
		if(upValIndex>=AVERAGE_SIZE) {
			upValIndex=0;
		}
	}
	if(newVal<0) {
		downVals[downValIndex]=-newVal;
		downValIndex++;
		if(downValIndex>=AVERAGE_SIZE) {
			downValIndex=0;
		}		
	}
  // 计算出平均值高于零
    
	float count=0;
	float total=0;
	for(int i=0; i<AVERAGE_SIZE; i++) {
		if(upVals[i]!=INVALID_ENTRY) {
			count++;
			total+=upVals[i];
		}
	}
	float averageUp=total/count;
  //和平均值低于零
    
	count=0;
	total=0;
	for(int i=0; i<AVERAGE_SIZE; i++) {
		if(downVals[i]!=INVALID_ENTRY) {
			count++;
			total+=downVals[i];
		}
	}
	float averageDown=total/count;

  
	if(newVal<-0.5*averageDown) {
		wasDown=true;
	}
	
	if(newVal>=0.5*averageUp && wasDown) {
		wasDown=false;
    
		if(time-periodStart<MAX_PERIOD && time-periodStart>MIN_PERIOD) {
			periods[periodIndex]=time-periodStart;
			periodTimes[periodIndex]=time;
			periodIndex++;
            NSLog(@"\n PERIOD INDEX = %d", periodIndex);
			if(periodIndex>=MAX_PERIODS_TO_STORE) {
                float hrv = [self calculateRMSSD];
                [self.delegate rmssdIsReady:hrv];
                periodIndex=0;
			}
		}
		periodStart=time;
	} 
	if(newVal<-0.5*averageDown) {
		return -1;
	} else if(newVal>0.5*averageUp) {
		return 1;
	}
	return 0;
}
/*
 static func calcRMSSD(_ intervals: [Double]) -> Double {
     var d = 0.0

     let size = intervals.count
     for i in 0 ..< size - 1 {
         let interval0 = intervals[i]
         let interval1 = intervals[i + 1]
         let diff = interval1 - interval0
         d += (diff * diff)
     }

     return sqrt(d / Double(size - 1))
 }

 
 */
-(float) calculateRMSSD {
    float d = 0.0;
    float size = MAX_PERIODS_TO_STORE-1;
    for (int i = 0; i < MAX_PERIODS_TO_STORE-1; i++) {
        float interval0 = periodTimes[i];
        float interval1 = periodTimes[i+1];
        float diff = interval1 - interval0;
        
        d += (diff * diff);
    }
    
    return sqrt(d/size);
}

-(float) getAverage {
	double time=CACurrentMediaTime();
	double total=0;
	double count=0;
	for(int i=0; i<MAX_PERIODS_TO_STORE; i++) {

        if(periods[i]!=INVALID_ENTRY  && time-periodTimes[i]<10) {
			count++;
			total+=periods[i];
		}
	}
	if(count>2) {
		return total/count;
	}
	return INVALID_PULSE_PERIOD;
}

@end
