/**********************************************************************************
 STKBufferingDataSource.m
 
 Created by Thong Nguyen on 16/10/2012.
 https://github.com/tumtumtum/audjustable
 
 Copyright (c) 2012-2014 Thong Nguyen (tumtumtum@gmail.com). All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. All advertising materials mentioning features or use of this software
 must display the following acknowledgement:
 This product includes software developed by Thong Nguyen (tumtumtum@gmail.com)
 4. Neither the name of Thong Nguyen nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY Thong Nguyen ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THONG NGUYEN BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **********************************************************************************/

#import "STKBufferingDataSource.h"

@interface STKBufferingDataSource()
{
@private
    int bufferStartIndex;
    int bufferStartFileOffset;
    int bufferBytesUsed;
    int bufferBytesTotal;
    SInt64 position;
    uint8_t* buffer;
    STKDataSource* dataSource;
}
@end

@implementation STKBufferingDataSource

-(id) initWithDataSource:(STKDataSource*)dataSourceIn withMaxSize:(int)maxSizeIn
{
    if (self = [super init])
    {
        self->dataSource = dataSourceIn;
        self->bufferBytesTotal = maxSizeIn;
        
        self->dataSource.delegate = self.delegate;
    }
    
    return self;
}

-(void) dealloc
{
	self->dataSource.delegate = nil;
    
    free(self->buffer);
}

-(void) createBuffer
{
    if (self->buffer == nil)
    {
        self->bufferBytesTotal = MIN((int)self.length, self->bufferBytesTotal);
        self->bufferBytesTotal = MAX(self->bufferBytesTotal, 1024);
        
        self->buffer = malloc(self->bufferBytesTotal);
    }
}

-(SInt64) length
{
    return self->dataSource.length;
}

-(void) seekToOffset:(SInt64)offset
{
}

-(void) dataSourceDataAvailable:(STKDataSource*)dataSourceIn
{
    if (self->buffer == nil)
    {
    	[self createBuffer];
    }

    UInt32 start = (bufferStartIndex + bufferBytesUsed) % bufferBytesTotal;
    UInt32 end = (position - bufferStartFileOffset + bufferStartIndex) % bufferBytesTotal;
    
    if (start >= end)
    {
        int bytesRead;
        int bytesToRead = bufferBytesTotal - start;
        
        if (bytesToRead > 0)
        {
            bytesRead = [dataSource readIntoBuffer:self->buffer + bufferStartIndex withSize:bytesToRead];
        }
        else
        {
            bytesToRead = start;
            
            bytesRead = [dataSource readIntoBuffer:self->buffer withSize:bytesToRead];
        }
        
        if (bytesRead < 0)
        {
            return;
        }
        
        bufferStartIndex += bytesRead;
        bufferBytesUsed += bytesRead;
    }
    else
    {
        int bytesToRead = end - start;
        
        int bytesRead = [dataSource readIntoBuffer:self->buffer + start withSize:bytesToRead];
        
        if (bytesToRead < 0)
        {
            return;
        }
        
    	bufferStartIndex += bytesRead;
        bufferBytesUsed += bytesRead;
    }
}

-(void) dataSourceErrorOccured:(STKDataSource*)dataSourceIn
{
    [self.delegate dataSourceErrorOccured:self];
}

-(void) dataSourceEof:(STKDataSource*)dataSourceIn
{
}

@end
