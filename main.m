// Builds with clang main.m -framework Foundation -framework CoreBluetooth -o mip.out && ./mip.out

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#define MAX_DATA 64

#define READ_SERVICE_UUID @"FFE0"
#define SEND_SERVICE_UUID @"FFE5"

unsigned char hexDigitToNum(char d)
{
	if (d>='a' && d<='f')
		return (d-'a')+10;
	if (d>='A' && d<='F')
		return (d-'A')+10;
	if (d>='0' && d<='9')
		return (d-'0');
	NSLog(@"Bad hex digit %d (%c)", d, d);
	return 0;
}

struct MiPInputs
{
	const char *name;
	unsigned char cmd;
};

struct MiPInputs inputs[]=
{
	{"Current MIP Game Mode", 0x82},
	{"MIP status", 0x79},
	{"Weight update", 0x81},
	{"Chest LED", 0x83},
	{"Head LED", 0x8B},
	{"Odometer reading", 0x85},
	{"Gesture Detect", 0x0A},
	{"Radar Mode Status", 0x0D},
	{"Radar Response", 0x0C},
	{"Mip Detection Status", 0x0F},
	{"Mip Detected", 0x04},
	{"Shake Detected", 0x1A},
	{"IR Control Status", 0x11},
	{"MIP User Or Other Eeprom Data", 0x13},
	{"Mip Hardware Info", 0x19},
	{"Mip Volume", 0x16},
	{"Receive IR Dongle code", 0x03},
	{"Clap times", 0x1D},
	{"Clap Status", 0x1F},
	{"EndMarker", 0}
};

@interface MIP : NSObject {
}
- (void) startScan;
@property (retain, nonatomic) NSMutableArray    *foundPeripherals;
@end    

@interface MIP () <CBCentralManagerDelegate, CBPeripheralDelegate> {
	CBCentralManager *mgr;
	CBCharacteristic *writeCharacteristic;
}
@end

@implementation MIP

@synthesize foundPeripherals;

- (id) init
{
	if (self=[super init])
	{
		mgr=[[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil];
		foundPeripherals = [[NSMutableArray alloc] init];
		writeCharacteristic=NULL;
	}
	return self;
}

- (void) dealloc
{
	NSLog(@"Shutting down");
	[mgr release];
	[foundPeripherals release];
	[super dealloc];
}

- (void) startScan
{
	NSLog(@"Starting scan");
	NSLog(@"Starting scan %ld", mgr.state);
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, YES);
	NSLog(@"Starting scan %ld", mgr.state);
	NSArray *services = [NSArray arrayWithObjects:@[[CBUUID UUIDWithString:SEND_SERVICE_UUID]], @[[CBUUID UUIDWithString:READ_SERVICE_UUID]], nil];
	[mgr scanForPeripheralsWithServices:services options:nil];
	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 3, NO);
	for (CBPeripheral *peripheral in foundPeripherals)
	{
		NSLog(@"Connecting %ld", peripheral.state);
		[mgr connectPeripheral:peripheral options:nil]; // Why?! Should have already happened in discovery
		while (peripheral.state==CBPeripheralStateConnecting)
		{
			NSLog(@"Connecting %ld", peripheral.state);
			CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, YES);
		}
		if (peripheral.state==CBPeripheralStateConnected)
		{
			NSLog(@"connected %@", peripheral.name);
			while (!writeCharacteristic)
			{
				NSLog(@"Waiting for write characteristic");
				CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, NO);
			}
			NSLog(@"Writing to characteristic");

			while (true)
			{
				char buffer[1024];
				unsigned char data[MAX_DATA];
				NSLog(@"Get command");
				gets(buffer);
				int strLength=strlen(buffer);
				if (strLength==0)
				{
					break;
				}
				else if (strLength&1)
				{
					NSLog(@"Must be an even number of hex digits");
				}
				else
				{
					int length=0;
					while (length*2<strLength && length<MAX_DATA)
					{
						data[length]=hexDigitToNum(buffer[2*length+0])<<4;
						data[length]+=hexDigitToNum(buffer[2*length+1]);
						length++;
					}
					NSLog(@"Sending %d bytes", length);
					NSData *dataToWrite = [NSData dataWithBytesNoCopy:data length:length freeWhenDone:NO];
					[peripheral writeValue:dataToWrite forCharacteristic:writeCharacteristic type:CBCharacteristicWriteWithResponse];
				}	
				CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, NO);
			}
		}
					
		NSLog(@"Disconnecting");
		[mgr cancelPeripheralConnection:peripheral];
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, YES);
	}
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	NSLog(@"centralManagerDidUpdateState");
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
	NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
	NSLog(@"didRetrieveConnectedPeripherals");
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	if (![foundPeripherals containsObject:peripheral])
	{
		NSLog(@"didDiscoverPeripheral: Name: %@", peripheral.name);
		NSLog(@"didDiscoverPeripheral: Advertisment Data: %@", advertisementData);
		NSLog(@"didDiscoverPeripheral: RSSI: %@", RSSI);
        [foundPeripherals addObject:peripheral];
		NSLog(@"Stopping scan");
    	[mgr stopScan];
        [peripheral retain];
		peripheral.delegate=self;
		NSLog(@"Connecting from discovery");
		[mgr connectPeripheral:peripheral options:nil];
		//CFRunLoopStop(CFRunLoopGetCurrent());
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	NSLog(@"didConnectPeripheral %@", peripheral.name);
	[peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	NSLog(@"didFailToConnectPeripheral");
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	NSLog(@"didDisconnectPeripheral %@", error);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{ 
	NSLog(@"Discovered services %@", peripheral.name);
    for (CBService *service in peripheral.services)
	{
        //NSLog(@"Discovered service %@", service);
		if ([service.UUID isEqual:[CBUUID UUIDWithString:READ_SERVICE_UUID]])
		{
			NSLog(@"Found MiP receive data service");
			[peripheral discoverCharacteristics:nil forService:service];
		}
		else if ([service.UUID isEqual:[CBUUID UUIDWithString:SEND_SERVICE_UUID]])
		{
			NSLog(@"Found MiP send data service");
			[peripheral discoverCharacteristics:nil forService:service];
		}
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics)
	{
        NSLog(@"Discovered characteristic %@", characteristic);
		if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE4"]])
		{
			NSLog(@"Found MiP NOTIFY characteristic");
    		[peripheral setNotifyValue:YES forCharacteristic:characteristic];
		}
		else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FFE9"]])
		{
			NSLog(@"Found MiP WRITE characteristic");
			writeCharacteristic=characteristic;
		}
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{ 
	NSData *data = characteristic.value;
	unsigned char realData[MAX_DATA];
	int length=0;
	const char *pHexData=data.bytes;
	for (NSUInteger i=0; length<MAX_DATA && i<data.length; i+=2)
	{
		realData[length++]=(hexDigitToNum(pHexData[i])<<4) | hexDigitToNum(pHexData[i+1]);
	}
	NSLog(@"The command is: %02x and has %d extra bytes (%s)", realData[0], length-1, pHexData+2);
	char buffer[1024];
	for (int i=0; i<sizeof(inputs)/sizeof(inputs[0]); i++)
	{
		if (realData[0]==inputs[i].cmd)
		{
			sprintf(buffer, "Decodes as: %s", inputs[i].name);
		}
	}
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{ 
    if (error)
	{
        NSLog(@"Error changing notification state: %@", [error localizedDescription]);
    }
}

@end

int main(int argc, char **argv)
{
	MIP *mip=[[MIP alloc] init];
	[mip startScan];
	[mip release];
}
