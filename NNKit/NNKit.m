//
//  NNKit.m
//  NNKit
//
//  Created by Scott Perry on 09/05/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNKit.h"

#include <errno.h>
#include <sys/sysctl.h>

_Bool osIsYosemite() {
    const char * const yosemiteVersionNumeric = "14";
    char str[256];
    size_t size = sizeof(str);
    int ret = sysctlbyname("kern.osversion", str, &size, NULL, 0);
    assert(ret == 0);
    // First character after the numeric is a letter (not a three-digit major version)
    if (str[strlen(yosemiteVersionNumeric)] < 65 || str[strlen(yosemiteVersionNumeric)] > 90) { return false; }
    return !strncmp(yosemiteVersionNumeric, str, strlen(yosemiteVersionNumeric));
}
