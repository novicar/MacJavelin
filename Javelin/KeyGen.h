#pragma once

class CKeyGen
{
public:
	CKeyGen(void);
	~CKeyGen(void);
	static char* Iv( char* iv );
	static char* Key( char* key );

private:
	static char key0[32];
	static char key1[32];
	static char key2[32];

	static char iv0[32];
	static char iv1[32];
	static char iv2[32];
};
