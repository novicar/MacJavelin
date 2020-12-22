//
//  Base64.cpp
//  Javelin
//
//  Created by harry on 8/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "Base64.h"

/*
 ** Translation Table as described in RFC1113
 */
const char CBase64::cb64[]="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/*
 ** Translation Table to decode (created by author)
 */
const char CBase64::cd64[]="|$$$}rstuvwxyz{$$$$$$$>?@ABCDEFGHIJKLMNOPQRSTUVW$$$$$$XYZ[\\]^_`abcdefghijklmnopq";

void CBase64::decodeblock( BYTE in[4], BYTE out[3] )
{
	out[ 0 ] = (unsigned char ) (in[0] << 2 | in[1] >> 4);
    out[ 1 ] = (unsigned char ) (in[1] << 4 | in[2] >> 2);
    out[ 2 ] = (unsigned char ) (((in[2] << 6) & 0xc0) | in[3]);
}

void CBase64::Decode( const char* szEncodedString, BYTE* result, UINT nMaxLen )
{
	BYTE in[4], out[3], v;
    INT i, len;
	UINT nIndex=0, nOut=0;
	
    while( szEncodedString[nIndex] != '\x0' ) 
	{
        for( len = 0, i = 0; i < 4 && szEncodedString[nIndex] != '\x0'; i++ ) {
            v = 0;
            while( szEncodedString[nIndex] != '\x0' && v == 0 ) {
                v = (BYTE) szEncodedString[nIndex++];
                v = (BYTE) ((v < 43 || v > 122) ? 0 : cd64[ v - 43 ]);
                if( v ) {
                    v = (BYTE) ((v == '$') ? 0 : v - 61);
                }
            }
            if( szEncodedString[nIndex] != '\x0' ) {
                len++;
                if( v ) {
                    in[ i ] = (BYTE) (v - 1);
                }
            }
            else {
                in[i] = 0;
            }
        }
        if( len ) {
            decodeblock( in, out );
            for( i = 0; i < len - 1 && nOut<nMaxLen; i++ ) {
                //putc( out[i], outfile );
				result[nOut++] = out[i];
            }
        }
    }
}

/*
 void encodeblock( unsigned char in[3], unsigned char out[4], int len )
 {
	out[0] = cb64[ in[0] >> 2 ];
	out[1] = cb64[ ((in[0] & 0x03) << 4) | ((in[1] & 0xf0) >> 4) ];
	out[2] = (unsigned char) (len > 1 ? cb64[ ((in[1] & 0x0f) << 2) | ((in[2] & 0xc0) >> 6) ] : '=');
	out[3] = (unsigned char) (len > 2 ? cb64[ in[2] & 0x3f ] : '=');
 }
 
 void encode( FILE *infile, FILE *outfile, int linesize )
 {
	unsigned char in[3], out[4];
	int i, len, blocksout = 0;
 
	while( !feof( infile ) ) {
		len = 0;
		for( i = 0; i < 3; i++ ) {
			in[i] = (unsigned char) getc( infile );
			if( !feof( infile ) ) {
				len++;
			}
			else {
				in[i] = 0;
			}
		}
		if( len ) {
			encodeblock( in, out, len );
			for( i = 0; i < 4; i++ ) {
				putc( out[i], outfile );
			}
			blocksout++;
		}
		if( blocksout >= (linesize/4) || feof( infile ) ) {
			if( blocksout ) {
				fprintf( outfile, "\r\n" );
			}
			blocksout = 0;
		}
	}
 }
 */