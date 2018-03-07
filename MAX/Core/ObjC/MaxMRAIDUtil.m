//
//  MaxMRAIDUtil.m
//  MRAID
//
//  Created by Jay Tucker on 11/8/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

#import "MaxMRAIDUtil.h"

static NSString *MaxMRAIDUtilErrorDomain = @"MaxMRAIDUtilErrorDomain";

@implementation MaxMRAIDUtil

+ (NSString *)processRawHtml:(NSString *)rawHtml error:(NSError **)error
{
    NSString *processedHtml = rawHtml;
    NSRange range;
    
    // Remove the mraid.js script tag.
    // We expect the tag to look like this:
    // <script src='mraid.js'></script>
    // But we should also be to handle additional attributes and whitespace like this:
    // <script  type = 'text/javascript'  src = 'mraid.js' > </script>
    
    NSString *pattern = @"<script\\s+[^>]*\\bsrc\\s*=\\s*([\\\"\\\'])mraid\\.js\\1[^>]*>\\s*</script>\\n*";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:error];
    processedHtml = [regex stringByReplacingMatchesInString:processedHtml
                                                    options:0
                                                      range:NSMakeRange(0, [processedHtml length])
                                               withTemplate:@""];
    
    // Add html, head, and/or body tags as needed.
    range = [rawHtml rangeOfString:@"<html"];
    BOOL hasHtmlTag = (range.location != NSNotFound);
    range = [rawHtml rangeOfString:@"<head"];
    BOOL hasHeadTag = (range.location != NSNotFound);
    range = [rawHtml rangeOfString:@"<body"];
    BOOL hasBodyTag = (range.location != NSNotFound);
    
    // basic sanity check
    if ((!hasHtmlTag && (hasHeadTag || hasBodyTag))) {
        *error = [self errorWithMessage:@"ERROR: html doesnt have an html tag AND it either has a head tag or body tag"];
        return nil;
    }
    
    // another basic sanity check
    if ((hasHtmlTag && !hasBodyTag)) {
        *error = [self errorWithMessage:@"ERROR: html has an html tag AND it doesn't have a body tag"];
        return nil;
    }
    
    if (!hasHtmlTag) {
        processedHtml = [NSString stringWithFormat:
                         @"<html>\n"
                         "<head>\n"
                         "</head>\n"
                         "<body>\n"
                         "%@"
                         "</body>\n"
                         "</html>",
                         processedHtml
                         ];
    } else if (!hasHeadTag) {
        // html tag exists, head tag doesn't, so add it
        pattern = @"<html[^>]*>";
        error = NULL;
        regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:error];
        processedHtml = [regex stringByReplacingMatchesInString:processedHtml
                                                        options:0
                                                          range:NSMakeRange(0, [processedHtml length])
                                                   withTemplate:@"$0\n<head>\n</head>"];
    }
    
    // Add meta and style tags to head tag.
    NSString *metaTag =
    @"<meta name='viewport' content='width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no' />";
    
    NSString *styleTag =
    @"<style>\n"
    "body { margin:0; padding:0; }\n"
    "*:not(input) { -webkit-touch-callout:none; -webkit-user-select:none; -webkit-text-size-adjust:none; }\n"
    "</style>";
    
    pattern = @"<head[^>]*>";
    error = NULL;
    regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:error];
    processedHtml = [regex stringByReplacingMatchesInString:processedHtml
                                                    options:0
                                                      range:NSMakeRange(0, [processedHtml length])
                                               withTemplate:[NSString stringWithFormat:@"$0\n%@\n%@", metaTag, styleTag]];
    
    return processedHtml;
}


#pragma mark - helper (After MRAID refactor we should have a dedicated error class)

+ (NSError *)errorWithMessage:(NSString *)message
{
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey: message
                               };
    NSError *error = [NSError errorWithDomain:MaxMRAIDUtilErrorDomain
                                         code:0
                                     userInfo:userInfo];
    return error;
}

@end
