//#define _ENTERPRISE_

using System;
using System.Web;
using System.Web.Services;
using System.Web.Services.Protocols;

using System.Xml;
using System.Xml.Schema;
using System.Xml.Serialization;
using System.Data;
using System.Data.SqlClient;

using System.Net.Mail;

using System.Runtime.Serialization.Formatters.Binary;
using System.Runtime.Serialization;
using System.IO;



[WebService(Namespace = "http://drumlinsecurity.co.uk/")]
//[WebService(Namespace = "http://localhost")]
[WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
//namespace DrumlinWebService
//{
public class Service : System.Web.Services.WebService
{
	private enum UserTypes
	{
		ADMINS = 0,
		STANDARD = 1,
		UNRESTRICTED_DRMS = 2,
		USER_SPECIFIC_DRMS = 4,
		WATERMARKS = 8,
		BULK_PUB = 16,
		GRABBER_OK = 32,
		SHOW_DOWNLOAD = 64,
		CAN_CREATE_EXE = 128
	};

	private const int MAX_DATA_LEN	= (1024 *1024);
	
	public const int ACTIVITY_ADD_USER		=	100;
	public const int ACTIVITY_UPLOAD_DOC	=	110;
	public const int ACTIVITY_UPLOAD_DOC_INFO=	111;
	public const int ACTIVITY_LOGIN			=	120;
	public const int ACTIVITY_REGISTER		=	130;
	public const int ACTIVITY_OPEN_DOC_OK	=	140;
	public const int ACTIVITY_OPEN_DOC_ERROR=	141;
	public const int ACTIVITY_PRINT_DOC_OK	=	142;
	public const int ACTIVITY_PRINT_DOC_ERROR=	143;
	public const int ACTIVITY_AUTH_OK		=	150;
	public const int ACTIVITY_AUTH_ERROR	=	151;
	public const int ACTIVITY_WRONG_CLIENT	=	152;
	public const int ACTIVITY_LOGIN_1		=	153;
	public const int ACTIVITY_MAIL_ERROR	=	154;
	public const int ACTIVITY_POST_AUTH_OK	=	155;//post authorisation
	
    public Service () 
    {
        //Uncomment the following line if using designed components 
        //InitializeComponent(); 
    }

	/// <summary>
	/// Method uses username and password to check if the user exists in the DB
	/// and, if does, it returns users type
	/// </summary>
	/// <param name="sUsername">Username</param>
	/// <param name="sPassword">Password</param>
	/// <returns>DocUser structure or null in case of error</returns>
	[WebMethod]
	public DocUser Login( string sUsername, string sPassword, out string sError ) 
	{
		sError = "";
		string sE = "";
		
		DocUser du = MyLogin( sUsername, sPassword, -1, out sError );
		
		if ( du != null )
		{
			AddActivity( du.m_nID, 0, ACTIVITY_LOGIN, string.Format("Successful login by user: {0}",sUsername), out sE );
		}
		else
		{
			AddActivity( 0, 0, ACTIVITY_LOGIN_1, "Login: "+sError, out sE );
		}
		return du;
	}
	
	[WebMethod]
	public DateTime GetServerDate()
	{
		return DateTime.Now;
	}
	
	[WebMethod]
	public string Version()
	{
		string sVersion = Encryption.Version.Text;
		sVersion += "\r\nWeb service: 1.06 24/Feb/2011";
		
		return sVersion;
	}

	[WebMethod]
	public DocUser LoginEncrypted( byte[] Username,  byte[] Password, out string sError ) 
	{
		sError = "";

		return LoginEncryptedEx( Username, Password, -1, out sError );
	}
		
	[WebMethod]
	public DocUser LoginEncryptedEx( byte[] Username,  byte[] Password, int nClientVer, out string sError ) 
	{
		sError = "";
		string sUsername, sPassword;
		
#if _ENTERPRISE_
		Encryption.E1 enc = new Encryption.E1();
		sUsername = enc.Dx3( Username, out sError );
#else
		Encryption.MyEncryption enc = new Encryption.MyEncryption();
		sUsername = enc.DecryptString( Username, out sError );
#endif
		
		if ( sUsername == null ) return null;
		
#if _ENTERPRISE_
		sPassword = enc.Dx3( Password, out sError );
#else
		sPassword = enc.DecryptString( Password, out sError );
#endif
		
		if ( sPassword == null ) return null;
		
		string sE = "";
		DocUser du = MyLogin( sUsername, sPassword, nClientVer, out sError );
		if ( du != null )
		{
			AddActivity( du.m_nID, 0, ACTIVITY_LOGIN, string.Format("Successful login by user: {0}",sUsername), out sE );
		}
		else
		{
			AddActivity( 0, 0, ACTIVITY_LOGIN_1, "LoginEncyptedEx: "+sError, out sE );
		}

		return du;
	}

		/// <summary>
	/// Returns user type of a user identified by username and password
	/// </summary>
	/// <param name="Username">Encrypted username</param>
	/// <param name="Password">Encrypted password</param>
	/// <param name="nClientVer">clientversion</param>
	/// <param name="sError">Diag text</param>
	/// <returns>User type</returns>
	[WebMethod]
	public int GetUserType( byte[] Username, byte[] Password, int nClientVer, out string sError )
	{
		sError = "";
		DocUser du = GetUserData( Username, Password, nClientVer, out sError );
		
		if ( du == null ) return -1;
		
		return du.m_nUserType;
	}
	
	[WebMethod]
	public DocUser GetUserData( byte[] Username,  byte[] Password, int nClientVer, out string sError ) 
	{
		sError = "";
		string sUsername, sPassword;
		
#if _ENTERPRISE_
		Encryption.E1 enc = new Encryption.E1();
		sUsername = enc.Dx3( Username, out sError );
#else
		Encryption.MyEncryption enc = new Encryption.MyEncryption();
		sUsername = enc.DecryptString( Username, out sError );
#endif

		if ( sUsername == null ) return null;
		
#if _ENTERPRISE_
		sPassword = enc.Dx3( Password, out sError );
#else
		sPassword = enc.DecryptString( Password, out sError );		
#endif
		if ( sPassword == null ) return null;
		
		DocUser du = MyLogin( sUsername, sPassword, nClientVer, out sError );
		if ( du != null )
		{
			du.m_ProhibitedDocs = GetProhibitedDocs( du.m_nID, out sError );
			du.m_nResult = 0;
						
			if ( nClientVer > 0 )
			{
				int nClient = CheckClientVersion( nClientVer, out sError );
				if ( nClient == nClientVer )
				{
					du.m_nResult = nClient;//wrong client!!!! 
					string sActivityDesc = string.Format( "User {0} ({1}) uses wrong client {2}", du.m_nID, sUsername, nClientVer );
					AddActivity( du.m_nID, 0, ACTIVITY_WRONG_CLIENT, sActivityDesc, out sError );	
				}
			}
		}
//		else
//		{
//			//string sTemp = "";
//			//AddActivity( 0, 0, ACTIVITY_LOGIN_1, "GetUserData: "+sError, out sTemp );	
//		}

		return du;
	}

	[WebMethod]
	public DocUser GetUserDataPDK(byte[] Username, byte[] Password, int nClientVer, out string sError)
	{
		sError = "";
		string sUsername, sPassword;

#if _ENTERPRISE_
		Encryption.E1 enc = new Encryption.E1();
		sUsername = enc.Dx3( Username, out sError );
#else
		Encryption.PDKEncryption enc = new Encryption.PDKEncryption();
		{
			byte[] d = enc.Decrypt(Username, out sError);

			if  (d == null ) return null;
			
			System.Text.Encoding unicode = System.Text.Encoding.Unicode;
			char[] chars = new char[ unicode.GetCharCount( d, 0, d.Length ) ];
			unicode.GetChars( d, 0, d.Length, chars, 0 );
			sUsername = new string( chars );
		}
#endif

#if _ENTERPRISE_
		sPassword = enc.Dx3( Password, out sError );
#else
		{
			byte[] d = enc.Decrypt(Password, out sError);

			if (d == null) return null;

			System.Text.Encoding unicode = System.Text.Encoding.Unicode;
			char[] chars = new char[unicode.GetCharCount(d, 0, d.Length)];
			unicode.GetChars(d, 0, d.Length, chars, 0);
			sPassword = new string(chars);
		}
#endif

		DocUser du = MyLogin(sUsername, sPassword, nClientVer, out sError);
		if (du != null)
		{
			du.m_ProhibitedDocs = GetProhibitedDocs(du.m_nID, out sError);
			du.m_nResult = 0;

			if (nClientVer > 0)
			{
				int nClient = CheckClientVersion(nClientVer, out sError);
				if (nClient == nClientVer)
				{
					du.m_nResult = nClient;//wrong client!!!! 
					string sActivityDesc = string.Format("User {0} ({1}) uses wrong client {2}", du.m_nID, sUsername, nClientVer);
					AddActivity(du.m_nID, 0, ACTIVITY_WRONG_CLIENT, sActivityDesc, out sError);
				}
			}
		}
		//		else
		//		{
		//			//string sTemp = "";
		//			//AddActivity( 0, 0, ACTIVITY_LOGIN_1, "GetUserData: "+sError, out sTemp );	
		//		}

		return du;
	}

	private int[] GetProhibitedDocs( int nUserID, out string sError ) 
	{
		sError = "";
		SqlConnection conn = null;

		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return null;
		}

		System.Collections.ArrayList list = new System.Collections.ArrayList();
		SqlCommand com = null;
		SqlDataReader reader = null;
		
		try 
		{
			com = new SqlCommand( "spGetProhibitedDocs", conn );
			com.Parameters.Add(new SqlParameter("@nUserID",		SqlDbType.Int)).Value = nUserID;
			com.CommandType = CommandType.StoredProcedure;
			reader = com.ExecuteReader();
			
			while ( reader.Read() )
			{
				list.Add( reader[ 0 ] );
			}
			
			int[] ProhibitedDocs = new int[ list.Count ];
			for( int i=0; i<list.Count; i++ )
			{
				ProhibitedDocs[i] = Convert.ToInt32( list[i] );
			}
			return ProhibitedDocs;
		}
		catch ( Exception ex )
		{
			//there was an error - interpret that like the trans doesn't exist!
			sError = ex.Message;
			return null;
		}
		finally 
		{
			if ( reader != null ) reader.Close();
			conn.Close();
		}
	}

	private int CheckClientVersion( int nClientVersion, out string sError ) 
	{
		sError = "";
		SqlConnection conn = null;

		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -2;
		}

		System.Collections.ArrayList list = new System.Collections.ArrayList();
		SqlCommand com = null;
		try 
		{
			com = new SqlCommand( "spCheckClient", conn );
			com.Parameters.Add(new SqlParameter("@nClientVer",		SqlDbType.Int)).Value = nClientVersion;
			com.CommandType = CommandType.StoredProcedure;
			SqlDataReader reader = com.ExecuteReader();
			
			if ( reader.Read() )
			{
				return Convert.ToInt32( reader[0] );
			}
			else
			{
				return 0;
			}			
		}
		catch ( Exception ex )
		{
			//there was an error - interpret that like the trans doesn't exist!
			sError = ex.Message;
			return -1;
		}
		finally 
		{
			conn.Close();
		}
	}

	[WebMethod]
	public int AddUser( DocUser user, out string sError)
	{
		sError = "";
		SqlConnection conn = null;

		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -10;
		}

		SqlCommand com = null;
		try
		{
			string sUsername, sPassword;
			string sDiskID="", sWinID="";

#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3(user.m_username, out sError);
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString(user.m_username, out sError);
#endif
			if (sUsername == null) return -20;

#if _ENTERPRISE_
			sPassword = enc.Dx3(user.m_password, out sError);
#else
			sPassword = enc.DecryptString(user.m_password, out sError);
#endif
			if (sPassword == null) return -30;
			
			if ( user.m_DiskID != null )
			{
#if _ENTERPRISE_
				sDiskID = enc.Dx3( user.m_DiskID, out sError );
#else
				sDiskID = enc.DecryptString( user.m_DiskID, out sError );
#endif
				if ( sDiskID == null ) return -40;
			}
			
			if ( user.m_WinID != null )
			{
#if _ENTERPRISE_
				sWinID = enc.Dx3( user.m_WinID, out sError );
#else
				sWinID = enc.DecryptString( user.m_WinID, out sError );
#endif
				if ( sWinID == null ) return -50;
			}

/*			if ( user.m_nClientID > 2130 && user.m_nClientID <= 2138 )
			{
				sError = "Please download and install newest Drumlin reader from\r\n\r\nhttp://www.drumlinsecurity.co.uk/Client/DrumlinSetup.zip";
				return -51;
			}*/
			int nClient = CheckClientVersion( user.m_nClientID, out sError );
			if ( nClient == user.m_nClientID )
			{
				string sDesc = string.Format( "User {0} ({1}) uses wrong client {2} (AddUser)", user.m_nID, sUsername, nClient );
				AddActivity( user.m_nID, 0, ACTIVITY_WRONG_CLIENT, sDesc, out sError );	

				sError = "Please download and install newest Drumlin reader from\r\n\r\nhttp://www.drumlinsecurity.co.uk/Client/DrumlinSetup.zip";
				return -51;
			}

			string sIP = "";
			try {
				sIP = HttpContext.Current.Request.ServerVariables["REMOTE_ADDR"].ToString();
			} catch {
			}
			
			/////////////////////////////
			com = new SqlCommand("spAddUser", conn);

/////////////// 143 -> 15
			user.m_nUserType = 15;
///////////////
			com.Parameters.Add(new SqlParameter("@sUsername",		SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sPassword",		SqlDbType.VarChar)).Value = sPassword;
			com.Parameters.Add(new SqlParameter("@sFirstName",		SqlDbType.VarChar)).Value = user.m_sFirstName;
			com.Parameters.Add(new SqlParameter("@sFamilyName",		SqlDbType.VarChar)).Value = user.m_sFamilyName;
			com.Parameters.Add(new SqlParameter("@sAddress1",		SqlDbType.VarChar)).Value = user.m_sAddress1;
			com.Parameters.Add(new SqlParameter("@sAddress2",		SqlDbType.VarChar)).Value = user.m_sAddress2;
			com.Parameters.Add(new SqlParameter("@sAddress3",		SqlDbType.VarChar)).Value = user.m_sAddress3;
			com.Parameters.Add(new SqlParameter("@sPostcode",		SqlDbType.VarChar)).Value = user.m_sPostcode;
			com.Parameters.Add(new SqlParameter("@sTown",			SqlDbType.VarChar)).Value = user.m_sTown;
			com.Parameters.Add(new SqlParameter("@sRegion",			SqlDbType.VarChar)).Value = user.m_sRegion;
			com.Parameters.Add(new SqlParameter("@sCountry",		SqlDbType.VarChar)).Value = user.m_sCountry;
			com.Parameters.Add(new SqlParameter("@sTelephone",		SqlDbType.VarChar)).Value = user.m_sTel;
			com.Parameters.Add(new SqlParameter("@sFax",			SqlDbType.VarChar)).Value = user.m_sFax;
			com.Parameters.Add(new SqlParameter("@sMobile",			SqlDbType.VarChar)).Value = user.m_sMob;
			com.Parameters.Add(new SqlParameter("@sEmail1",			SqlDbType.VarChar)).Value = user.m_sEmail1;
			com.Parameters.Add(new SqlParameter("@sEmail2",			SqlDbType.VarChar)).Value = user.m_sEmail2;
			com.Parameters.Add(new SqlParameter("@sWeb",			SqlDbType.VarChar)).Value = user.m_sWeb;
			com.Parameters.Add(new SqlParameter("@nUserType",		SqlDbType.Int)).Value =		user.m_nUserType;
			
			if ( user.m_WinID != null && user.m_DiskID != null )
			{
				com.Parameters.Add(new SqlParameter("@sWinID",			SqlDbType.VarChar)).Value = sWinID;
				com.Parameters.Add(new SqlParameter("@sDiskID",			SqlDbType.VarChar)).Value = sDiskID;
			}
			else
			{
				com.Parameters.Add(new SqlParameter("@sWinID",			SqlDbType.VarChar)).Value = "";
				com.Parameters.Add(new SqlParameter("@sDiskID",			SqlDbType.VarChar)).Value = "";
			}
			
			//I'm using clientID for sending ClientVersion to the DB! This is just a hack
			com.Parameters.Add(new SqlParameter("@nClientVer",		SqlDbType.Int)).Value =		user.m_nClientID;
			com.Parameters.Add(new SqlParameter("@sOrganisation",	SqlDbType.VarChar)).Value = user.m_sOrganisation;
			com.Parameters.Add(new SqlParameter("@sIP",	SqlDbType.VarChar)).Value = sIP;
			
			SqlParameter parResult = com.Parameters.Add("@nResult", SqlDbType.Int);
			parResult.Direction = ParameterDirection.Output;
			parResult.Value = -60;

			com.CommandType = CommandType.StoredProcedure;

			int nRes = com.ExecuteNonQuery();
			try
			{
				nRes = Convert.ToInt32(parResult.Value);
			}
			catch
			{
				nRes = 0;
			}


			string sActivityDesc = "";
			
			switch (nRes)
			{
				case -1:
					sActivityDesc = string.Format( "User {0} already exists", sUsername );
					//AddActivity( 0, 0, ACTIVITY_ADD_USER, sActivityDesc, out sError );	
					sError = "User already exists!";
					break;

				default:
					sError = "OK";
					
					user.m_nID = nRes;
					user.m_nClientID = nRes;

					sActivityDesc = string.Format( "User {0} [{1}] Added", sUsername, nRes );
					AddActivity( user.m_nID, 0, ACTIVITY_ADD_USER, sActivityDesc, out sError );	
					
					//add permission to read Mike's document
					//AddMikesDoc( nRes ); //remove on 23.05.2007 by Mike's request
										 //re-instated on 20.07.2007
										 //and again removed on 01.08.2007
					sUsername = GetRegCode( sUsername, sPassword, out sError );
					sError = sUsername;
					user.m_sRegCode = sUsername;
					SendRegistrationConfirmation( user );
					break;
			}
			return nRes;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -11;
		}
		finally
		{
			if (conn != null) conn.Close();
		}
	}
	
	[WebMethod]
	public int UpdateUserEx( DocUser user, bool bSendNotification, out string sError)
	{
		sError = "";
		SqlConnection conn = null;

		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -10;
		}

		SqlCommand com = null;
		try
		{
			string sUsername, sPassword;
			string sDiskID="", sWinID="";

#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3(user.m_username, out sError);
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString(user.m_username, out sError);
#endif
			if (sUsername == null) return -20;

#if _ENTERPRISE_
			sPassword = enc.Dx3(user.m_password, out sError);
#else
			sPassword = enc.DecryptString(user.m_password, out sError);
#endif
			if (sPassword == null) return -30;
			
			if ( user.m_DiskID != null )
			{
#if _ENTERPRISE_
				sDiskID = enc.Dx3( user.m_DiskID, out sError );
#else
				sDiskID = enc.DecryptString( user.m_DiskID, out sError );
#endif
				if ( sDiskID == null ) return -40;
			}
			
			if ( user.m_WinID != null )
			{
#if _ENTERPRISE_
				sWinID = enc.Dx3( user.m_WinID, out sError );
#else
				sWinID = enc.DecryptString( user.m_WinID, out sError );
#endif
				if ( sWinID == null ) return -50;
			}

			if ( user.m_nClientID != 0 )
			{
				int nClient = CheckClientVersion( user.m_nClientID, out sError );
				if ( nClient == user.m_nClientID )
				{
					string sDesc = string.Format( "User {0} ({1}) uses wrong client {2} (UpdateUserEx)", user.m_nID, sUsername, nClient );
					AddActivity( user.m_nID, 0, ACTIVITY_WRONG_CLIENT, sDesc, out sError );	
					sError = "Please download and install newest Drumlin reader from\r\n\r\nhttp://www.drumlinsecurity.co.uk/Client/DrumlinSetup.zip";
					return -51;
				}
			}
			
			/////////////////////////////
			com = new SqlCommand("spUpdateUser", conn);

			com.Parameters.Add(new SqlParameter("@sRegCode",		SqlDbType.VarChar)).Value = user.m_sRegCode;
			com.Parameters.Add(new SqlParameter("@sUsername",		SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sPassword",		SqlDbType.VarChar)).Value = sPassword;
			com.Parameters.Add(new SqlParameter("@sFirstName",		SqlDbType.VarChar)).Value = user.m_sFirstName;
			com.Parameters.Add(new SqlParameter("@sFamilyName",		SqlDbType.VarChar)).Value = user.m_sFamilyName;
			com.Parameters.Add(new SqlParameter("@sAddress1",		SqlDbType.VarChar)).Value = user.m_sAddress1;
			com.Parameters.Add(new SqlParameter("@sAddress2",		SqlDbType.VarChar)).Value = user.m_sAddress2;
			com.Parameters.Add(new SqlParameter("@sAddress3",		SqlDbType.VarChar)).Value = user.m_sAddress3;
			com.Parameters.Add(new SqlParameter("@sPostcode",		SqlDbType.VarChar)).Value = user.m_sPostcode;
			com.Parameters.Add(new SqlParameter("@sTown",			SqlDbType.VarChar)).Value = user.m_sTown;
			com.Parameters.Add(new SqlParameter("@sRegion",			SqlDbType.VarChar)).Value = user.m_sRegion;
			com.Parameters.Add(new SqlParameter("@sCountry",		SqlDbType.VarChar)).Value = user.m_sCountry;
			com.Parameters.Add(new SqlParameter("@sTelephone",		SqlDbType.VarChar)).Value = user.m_sTel;
			com.Parameters.Add(new SqlParameter("@sFax",			SqlDbType.VarChar)).Value = user.m_sFax;
			com.Parameters.Add(new SqlParameter("@sMobile",			SqlDbType.VarChar)).Value = user.m_sMob;
			com.Parameters.Add(new SqlParameter("@sEmail1",			SqlDbType.VarChar)).Value = user.m_sEmail1;
			com.Parameters.Add(new SqlParameter("@sEmail2",			SqlDbType.VarChar)).Value = user.m_sEmail2;
			com.Parameters.Add(new SqlParameter("@sWeb",			SqlDbType.VarChar)).Value = user.m_sWeb;
///////////////// 143 -> 15
			user.m_nUserType = 15;
/////////////////

			com.Parameters.Add(new SqlParameter("@nUserType",		SqlDbType.Int)).Value =		user.m_nUserType;
			com.Parameters.Add(new SqlParameter("@sOrganisation",	SqlDbType.VarChar)).Value = user.m_sOrganisation;
			
			if ( user.m_WinID != null && user.m_DiskID != null )
			{
				com.Parameters.Add(new SqlParameter("@sWinID",			SqlDbType.VarChar)).Value = sWinID;
				com.Parameters.Add(new SqlParameter("@sDiskID",			SqlDbType.VarChar)).Value = sDiskID;
			}
			else
			{
				//com.Parameters.Add(new SqlParameter("@sWinID",			SqlDbType.VarChar)).Value = "";
				//com.Parameters.Add(new SqlParameter("@sDiskID",			SqlDbType.VarChar)).Value = "";
				sError = "No IDs!";
				return -100;
			}
			
			SqlParameter parResult = com.Parameters.Add("@nResult", SqlDbType.Int);
			parResult.Direction = ParameterDirection.Output;
			parResult.Value = -60;

			com.CommandType = CommandType.StoredProcedure;

			int nRes = com.ExecuteNonQuery();
			try
			{
				nRes = Convert.ToInt32(parResult.Value);
			}
			catch
			{
				sError = "Error while trying to register user!";
				return -110;
			}

			string sActivityDesc = "";
			
			switch (nRes)
			{
				case -1:
					sActivityDesc = string.Format( "User with registration code: {0} doesn't exist", user.m_sRegCode );
					AddActivity( 0, 0, ACTIVITY_ADD_USER, sActivityDesc, out sError );	
					sError = sActivityDesc;
					break;

				default:
					sError = "OK";
					
					user.m_nID = nRes;
					user.m_nClientID = nRes;

					sActivityDesc = string.Format( "User {0} [{1}] Updated", sUsername, nRes );
					AddActivity( user.m_nID, 0, ACTIVITY_ADD_USER, sActivityDesc, out sError );	
					
					//add permission to read Mike's document
					//AddMikesDoc( nRes );
					//sUsername = GetRegCode( sUsername, sPassword, out sError );
					//sError = sUsername;
					//user.m_sRegCode = sUsername;
					
					if ( bSendNotification )
						SendRegistrationConfirmation( user );
					break;
			}
			return nRes;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -11;
		}
		finally
		{
			if (conn != null) conn.Close();
		}
	}
	
	[WebMethod]
	public int UpdateUser( DocUser user, out string sError)
	{
		sError = "";
		
		return UpdateUserEx( user, true, out sError );
	}
	
	[WebMethod]
	public string GetRegCode( byte[] username, byte[] password, out string sError )
	{
		sError = "";
		try
		{
			string sUsername, sPassword;
		
#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3( username, out sError );
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString( username, out sError );
#endif
			if ( sUsername == null ) return "-2";
		
#if _ENTERPRISE_
			sPassword = enc.Dx3( password, out sError );
#else
			sPassword = enc.DecryptString( password, out sError );
#endif
			if ( sPassword == null ) return "-3";

			return GetRegCode( sUsername, sPassword, out sError );
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return "-5";
		}
	}
	
	[WebMethod]
	public int ChangePassword( byte[] username, byte[] password, out string sError )
	{
		sError = "";
		SqlConnection conn = null;

		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -1;
		}

		SqlCommand com = null;
		try
		{
			string sUsername, sPassword;
		
#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3( username, out sError );
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString( username, out sError );
#endif
			if ( sUsername == null ) 
			{
				sError = "Can't decrypt username!";
				return -2;
			}
		
#if _ENTERPRISE_
			sPassword = enc.Dx3( password, out sError );
#else
			sPassword = enc.DecryptString( password, out sError );
#endif
			if ( sPassword == null )
			{
				sError = "Can't decrypt password!";
				return -3;
			}

			com = new SqlCommand( "spChangePassword", conn );
			com.Parameters.Add(new SqlParameter("@sUsername",	SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sNewPassword",	SqlDbType.VarChar)).Value = sPassword;
			com.CommandType = CommandType.StoredProcedure;

			SqlParameter parResult = com.Parameters.Add("@nResult", SqlDbType.Int );
			parResult.Direction = ParameterDirection.Output;
			parResult.Value = 0;

			int nRes = com.ExecuteNonQuery();
			
			nRes = Convert.ToInt32( parResult.Value );
			
			if ( nRes == -100 ) sError = "ERROR: This user doesn't exist!";
			else sError = "";
			
			return nRes;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -5;
		}
	}

	private string GetRegCode( string sUsername, string sPassword, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return "-1";
		}
		
		SqlCommand com = null;
		SqlDataReader reader = null;
		try
		{
			com = new SqlCommand( "spGetRegCode", conn );
			com.Parameters.Add(new SqlParameter("@sUsername",	SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sPassword",	SqlDbType.VarChar)).Value = sPassword;
			com.CommandType = CommandType.StoredProcedure;
			
			reader = com.ExecuteReader();
			reader.Read();
			
			Object oResult = reader.GetValue( 0 );
			if ( oResult != DBNull.Value )
			{
				return oResult.ToString();
			}
			else
			{
				return "-4";
			}
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return "-5";
		}
		finally
		{
			if ( reader != null ) reader.Close();
			if ( conn != null ) conn.Close();
		}
	}	
	
	/// <summary>
	/// Checks if the user is allowed to open the nDocID document
	/// 
	/// If yes, the method will return zero.
	/// </summary>
	/// <param name="nDocID">Document ID</param>
	/// <param name="nUserID">User ID</param>
	/// <param name="sError">Diag text</param>
	/// <returns>ZERO if successfull</returns>
	[WebMethod]
	public int CheckPermissions( int nDocID, int nUserID, out string sError )
	{
		sError = "";
		
		return CheckPermissionsEx( nDocID, nUserID, false, out sError );
	}


	/// <summary>
	/// Checks if the user is allowed to open the nDocID document
	/// If yes - the method will return zero.
	/// </summary>
	/// <param name="nDocID">Document to open</param>
	/// <param name="nUserID">User identity</param>
	/// <param name="bPrint">Print or screen</param>
	/// <param name="sError">Diag text</param>
	/// <returns>Zero if successful</returns>
	[WebMethod]
	public int CheckPermissionsEx( int nDocID, int nUserID, bool bPrint, out string sError )
	{
		sError = "";
		SqlConnection conn = null;

		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -1;//cannot connect to DB
		}

		SqlCommand com = null;
		SqlDataReader reader = null;
		try
		{
			com = new SqlCommand("spCheckPermission", conn);
			com.Parameters.Add(new SqlParameter("@nDocID", SqlDbType.Int)).Value = nDocID;
			com.Parameters.Add(new SqlParameter("@nUserID", SqlDbType.Int)).Value = nUserID;

			SqlParameter parResult = com.Parameters.Add("@nResult", SqlDbType.Int);
			parResult.Direction = ParameterDirection.Output;
			parResult.Value = -100;

			com.CommandType = CommandType.StoredProcedure;

			com.ExecuteNonQuery();

			int nRes = 0;
			try
			{
				nRes = Convert.ToInt32(parResult.Value);

				sError = "OK";

				if (nRes == -10) sError = "User record has expired!";
				else if (nRes == -20) sError = "User record doesn't exist!";
				else if (nRes == -30) sError = "Permission record doesn't exist!";
				else if (nRes == -40) sError = "Permission to read the document has expired!";
				else if (nRes == -50) sError = "Document can't be read yet!";
				else if (nRes != 0) sError = string.Format("Unknown error {0}!", nRes);

				//add activity
				string sDesc = string.Format("Open - UserID:{0} DocID:{1} Outcome: {2} ({3})",
					nUserID, nDocID, sError, nRes);
				string sError1 = "";

				if (nRes == 0)
					AddActivity(nUserID, nDocID, (bPrint?ACTIVITY_PRINT_DOC_OK:ACTIVITY_OPEN_DOC_OK), sDesc, out sError1);
				else
					AddActivity(nUserID, nDocID, (bPrint?ACTIVITY_PRINT_DOC_ERROR:ACTIVITY_OPEN_DOC_ERROR), sDesc, out sError1);

				return nRes;
			}
			catch
			{
				sError = "There was error while checking document permissions!";
				return -22;
			}

		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -5;
		}
		finally
		{
			if (reader != null) reader.Close();
			if (conn != null) conn.Close();
		}
	}

	/// <summary>
	/// By default add Mike's book in permission list of all newly added users
	/// </summary>
	/// <param name="nUserID">UserID</param>
	private void AddMikesDoc( int nUserID )
	{
		//SetPermissions( int[] aUserID, int[] aDocID, int nOpenCount, int nPrintCount, DateTime dtStart, DateTime dtExpiry, out string sError )
		
		int[] nUserIDs = new int[1];
		nUserIDs[0] = nUserID;
		
		int[] nDocIDs = new int[1];
		nDocIDs[0] = 55;//mike's document ID
		
		DateTime dtStart = DateTime.Now;
		DateTime dtEnd   = dtStart.AddDays( 16 );
		string sError = "";
		
		//sets permissions but NO notifications
		SetPermissions( nUserIDs, nDocIDs, 5, 0, -1, false, dtStart, dtEnd, 0, out sError );
	}

	/// <summary>
	/// Sends a registration confirmation to all newly registered users.
	/// </summary>
	/// <param name="user">User ID</param>
	private void SendRegistrationConfirmation( DocUser user )
	{
		try
		{
			string sError = "";
			string sUsername = GetConfigurationEntry( "MailUsername", out sError );
			string sPassword = GetConfigurationEntry( "MailPassword", out sError );
			string sMailServer = GetConfigurationEntry( "MailServer", out sError );
			
			if ( sMailServer.Length == 0 || sUsername.Length == 0 || sPassword.Length == 0 )
			{
				//can't send mails - check web.config
				AddActivity( user.m_nID, 0, ACTIVITY_MAIL_ERROR, "Mail server not defined!", out sError );
				return;
			}
			
//			SmtpClient mail = new SmtpClient( "mail4.hostinguk.net" );
//			mail.Credentials = new System.Net.NetworkCredential( "drumlinsec@drumlinsecurity.co.uk", "GSNZFxYu#9" );
			SmtpClient mail = new SmtpClient( sMailServer );
			mail.Credentials = new System.Net.NetworkCredential( sUsername, sPassword );
			
			string sText;
#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3( user.m_username, out sText );
			sPassword = enc.Dx3( user.m_password, out sText );
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString( user.m_username, out sText );
			sPassword = enc.DecryptString( user.m_password, out sText );
#endif
			if ( user.m_sFirstName.Length > 0 || user.m_sFamilyName.Length > 0 )
			{
				sText = string.Format( "Dear {0} {1},\r\n\r\n", user.m_sFirstName, user.m_sFamilyName );
			}
			else
			{
				sText = string.Format( "Dear {0},\r\n\r\n", sUsername );
			}
			
			sText += 
			"Thank you for registering your Drumlin PDF reader/publisher software.\r\n\r\n";
			
			sText += 
			"Welcome to the Drumlin Community! Your software installation is complete. Please click the link below to verify your email and fully activate your account.\r\n\r\n";
			
			sText +=
			"http://www.drumlinsecurity.co.uk/RegConf.aspx?code="+user.m_sRegCode+"\r\n\r\n";
			
			sText +=
			"The software is free, so please make use of the secure publishing facilities which are fully explained on the website:\r\nhttp://www.drumlinsecurity.co.uk/";

			sText +=
			"\r\n\r\nYour registration details are provided below - please keep a copy of this information. Your customer reference number is available via the Drumlin reader/publisher Help menu, \"About\" form.\r\n\r\n";

			
			string sServer = "";
			try { sServer = this.Server.MachineName; }
			catch {}
			
			sText += string.Format( 
				"Your registration details:\r\n\r\nCustomer reference: {0} (may be required for ordering purposes)\r\nUsername: {1}\r\nPassword: {2}\r\nEmail Address: {3}\r\nServer: {4}\r\n\r\n",
				user.m_sRegCode, sUsername, sPassword, user.m_sEmail1, sServer );
			sText += "Changing your details: If you wish to alter the email address to be used or your optional details then please send an email to:\r\nsupport@drumlinsecurity.co.uk\r\n\r\n";
			sText += "Using the software: The Welcome document distributed with the installation provides details on the use of the Drumlin reader. Please explore the menu items to familiarise yourself with its operation. If you have used the Adobe PDF reader you will find the Drumlin reader/publisher works in much the same manner. There is also a lot of help and information provided on the website.\r\n\r\n";
			//sText += "Evaluation files/documents: You may be provided with access to one or more evaluation documents. Such documents may be downloaded and viewed without requiring an authorization code, but will have limitations on the number of times they may be viewed, will not be printable, and may expire after a preset period.\r\n\r\n";
			sText += "Technical questions/fault reports: Frequently asked questions (FAQs) may be reviewed by visiting: http://www.drumlinsecurity.co.uk/faqs.html. Please send details of any unresolved technical issues or questions you may have regarding the Drumlin reader to: support@druminsecurity.co.uk - we will respond as soon as possible. Note that questions relating to Microsoft products, such as .NET installation, usage and impact on other software, should be addressed to Microsoft.\r\n\r\n";

			sText += "Thank you\r\n\r\nDrumlin Support\r\n";

/*			sText = string.Format(
				"Dear {0} {1},\r\n\r\nThank you for registering at DrumlinSecurity.co.uk!\r\n\r\nYour registration information is:\r\nUsername: {2}\r\nUserID: {3}\r\n",
				user.m_sFirstName, user.m_sFamilyName,
				(sUsername==null?"":sUsername), user.m_nID );*/

			MailMessage message = new MailMessage( "drumlinsec@drumlinsecurity.co.uk", user.m_sEmail1, "Welcome to Drumlin Security", sText );
			
			mail.Send( message );
		}
		catch ( Exception ex )
		{
//			sError = ex.Message;
//			return false;
		}
		finally
		{
		}

	}

	/// <summary>
	/// Checks if username/password is OK
	/// </summary>
	/// <param name="username">encrypted username</param>
	/// <param name="password">encrypted password</param>
	/// <param name="sError">diagnostic text</param>
	/// <returns></returns>
	[WebMethod]
	public int CheckUser( byte[] username, byte[] password, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -10;
		}
		
		SqlCommand com = null;
		try
		{
			string sUsername, sPassword;
			//string sDiskID, sWinID;
		
#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3( username, out sError );
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString( username, out sError );
#endif
			if ( sUsername == null ) return -20;
		
#if _ENTERPRISE_
			sPassword = enc.Dx3( password, out sError );
#else
			sPassword = enc.DecryptString( password, out sError );
#endif
			if ( sPassword == null ) return -30;

			com = new SqlCommand( "spCheckUserEx", conn );
			com.Parameters.Add(new SqlParameter("@sUsername",	SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sPassword",	SqlDbType.VarChar)).Value = sPassword;
			SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
			parResult.Direction	= ParameterDirection.Output;
			parResult.Value = -100;
			com.CommandType = CommandType.StoredProcedure;
			
			int nID = 0;
			com.ExecuteNonQuery();
			try
			{
				nID = Convert.ToInt32(parResult.Value);
				
				return nID;
			}
			catch 
			{
				sError = "There was error while checking user!";
				return -22;
			}
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -50;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}
	

	[WebMethod]
	public DocUser CheckUserSettings( int nUserID, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		SqlDataReader reader = null;
		
		try
		{
			com = new SqlCommand( "spCheckUserSettings", conn );
			
			com.Parameters.Add(new SqlParameter("@nUserID",		SqlDbType.Int)).Value = nUserID;
			com.CommandType = CommandType.StoredProcedure;
			
			reader = com.ExecuteReader();

			if ( reader.Read() )
			{
				DateTime dt = DateTime.Now.AddYears(1);
				//int nUserType = 0;
				DocUser du = new DocUser();
				try
				{
					du.m_nID = nUserID;
					du.m_nClientID = nUserID;
					du.m_dtExpires = Convert.ToDateTime( reader[ "Expires" ] );
					du.m_nUserType = Convert.ToInt32( reader[ "UserType" ] );
					
					return du;
				}
				catch ( Exception ex )
				{
					sError = ex.Message;
					return null;
				}
			}
			else
			{
				sError = "User settings not found!";
				return null;
			}
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally
		{
			if ( reader != null ) reader.Close();
			if ( conn != null ) conn.Close();
		}
	}
	
	/// <summary>
	/// Method checks username.password and email
	/// </summary>
	/// <param name="username"></param>
	/// <param name="password"></param>
	/// <param name="sEmail"></param>
	/// <param name="sError"></param>
	/// <returns></returns>
	[WebMethod]
	public int CheckUserAndEmail( byte[] username, byte[] password, string sEmail, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -10;
		}
		
		SqlCommand com = null;
		try
		{
			string sUsername, sPassword;
			//string sDiskID, sWinID;
		
#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3( username, out sError );
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString( username, out sError );
#endif
			if ( sUsername == null ) return -20;
		
#if _ENTERPRISE_
			sPassword = enc.Dx3( password, out sError );
#else
			sPassword = enc.DecryptString( password, out sError );
#endif
			if ( sPassword == null ) return -30;

			//sError = "U:"+sUsername+" P:"+sPassword+" E:"+sEmail;
			
			com = new SqlCommand( "spCheckUserAndEmail", conn );
			com.Parameters.Add(new SqlParameter("@sUsername",	SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sPassword",	SqlDbType.VarChar)).Value = sPassword;
			com.Parameters.Add(new SqlParameter("@sEmail",		SqlDbType.VarChar)).Value = sEmail;
			SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
			parResult.Direction	= ParameterDirection.Output;
			parResult.Value = -100;
			com.CommandType = CommandType.StoredProcedure;
			
			int nID = 0;
			com.ExecuteNonQuery();
			try
			{
				nID = Convert.ToInt32(parResult.Value);
				
				return nID;
			}
			catch 
			{
				sError = "There was error while checking user!";
				return -22;
			}
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -50;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}
	
	[WebMethod]
	public int RegisterUserEx( byte[] username, byte[] password, byte[] WinID, byte[] DiskID, out int nUserType, out string sError )
	{
		nUserType = 0;
		sError = "";
		
		return RegisterUserNew( username, password, WinID, DiskID,  0, out nUserType, out sError );
	}
	/// <summary>
	/// Registers new user and updates his/her record in the DB with this user IDs
	/// </summary>
	/// <param name="username"></param>
	/// <param name="password"></param>
	/// <param name="WinID"></param>
	/// <param name="DiskID"></param>
	/// <param name="sError"></param>
	/// <returns></returns>
	[WebMethod]
	public int RegisterUserNew( byte[] username, byte[] password, byte[] WinID, byte[] DiskID, int nClientVer, out int nUserType, out string sError )
	{
		sError = "";
		nUserType = 0;
		
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -10;
		}
		
		SqlCommand com = null;
		SqlCommand comCheck = null;
		try
		{
			string sUsername, sPassword;
			string sDiskID, sWinID;
		
#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3( username, out sError );
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString( username, out sError );
#endif
			if ( sUsername == null ) return -20;
		
#if _ENTERPRISE_
			sPassword = enc.Dx3( password, out sError );
#else
			sPassword = enc.DecryptString( password, out sError );
#endif
			if ( sPassword == null ) return -30;

#if _ENTERPRISE_
			sDiskID = enc.Dx3( DiskID, out sError );
#else
			sDiskID = enc.DecryptString( DiskID, out sError );
#endif
			if ( sDiskID == null ) return -40;

#if _ENTERPRISE_
			sWinID = enc.Dx3( WinID, out sError );
#else
			sWinID = enc.DecryptString( WinID, out sError );
#endif
			if ( sWinID == null ) return -50;

			//Before doing actual registration - check DiskID and WinID and 
			//if they don't match don't allow registration
			comCheck = new SqlCommand( "spCheckUser", conn );
			comCheck.Parameters.Add(new SqlParameter("@sUsername",	SqlDbType.VarChar)).Value = sUsername;
			comCheck.Parameters.Add(new SqlParameter("@sPassword",	SqlDbType.VarChar)).Value = sPassword;
			comCheck.Parameters.Add(new SqlParameter("@sWinID",		SqlDbType.VarChar)).Value = sWinID;
			comCheck.Parameters.Add(new SqlParameter("@sDiskID",	SqlDbType.VarChar)).Value = sDiskID;
			SqlParameter parResult1 = comCheck.Parameters.Add( "@nResult",	SqlDbType.Int );
			parResult1.Direction	= ParameterDirection.Output;
			parResult1.Value = -100;

			SqlParameter parUserType = comCheck.Parameters.Add( "@nUserType",	SqlDbType.Int );
			parUserType.Direction	= ParameterDirection.Output;
			parUserType.Value = 0;

			comCheck.CommandType = CommandType.StoredProcedure;
			
			int nID = comCheck.ExecuteNonQuery();
			try{
				nID = Convert.ToInt32(parResult1.Value);
				nUserType = Convert.ToInt32( parUserType.Value );
			} catch {
				sError = "There was error while checking user!";
				return -22;
			}
			
			//AddActivity( 0, 0, string.Format("spCheckUser:{0}", nID), out sError );
			
			if ( nID == -10 )
			{
				//user exists but has wrong IDs
				sError = "Username exists - please select a different username for registration!";
				return -23;
			}
			
			//Now, do the actual registration
			com = new SqlCommand( "spRegisterUser", conn );

			com.Parameters.Add(new SqlParameter("@sUsername",	SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sPassword",	SqlDbType.VarChar)).Value = sPassword;
			com.Parameters.Add(new SqlParameter("@sWinID",		SqlDbType.VarChar)).Value = sWinID;
			com.Parameters.Add(new SqlParameter("@sDiskID",		SqlDbType.VarChar)).Value = sDiskID;
			com.Parameters.Add(new SqlParameter("@nClientVer",	SqlDbType.Int)).Value = nClientVer;
			
			SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
			parResult.Direction	= ParameterDirection.Output;
			parResult.Value = -60;

			com.CommandType = CommandType.StoredProcedure;
			
			int nRes = com.ExecuteNonQuery();
            try
            {
                nRes = Convert.ToInt32(parResult.Value);
            }
            catch
            {
                nRes = 0;
            }
			
			string sTemp = "";
			
			switch( nRes )
			{
			case -1:
				sError = "User not found! ("+sUsername+")";
				break;
			
			case -2:
				sError = "Wrong WinID! ("+sWinID+")";
				break;
			
			case -3:
				sError = "Wrong DiskID! ("+sDiskID+")";
				break;
				
			case 0:
//				sError = "Already registered";
				sTemp = GetRegCode( sUsername, sPassword, out sError );
				sError = sTemp;
				nRes = nID;
				break;
			
			default:
				//sError = "OK";
				sTemp = GetRegCode( sUsername, sPassword, out sError );
				sError = sTemp;
				break;
			}
			
			string sActivityDesc = "RegisterUserEx() "+sError;
			sTemp = "";
			AddActivity( 0, 0, ACTIVITY_REGISTER, sActivityDesc, out sTemp );

			return nRes;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -11;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
		
	}
		
	[WebMethod]
	public int RegisterUserNewWithOrg( byte[] username, byte[] password, byte[] WinID, byte[] DiskID, int nClientVer, string sOrganisation, out int nUserType, out string sError )
	{
		sError = "";
		nUserType = 0;
		
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -10;
		}
		
		SqlCommand com = null;
		SqlCommand comCheck = null;
		try
		{
			string sUsername, sPassword;
			string sDiskID, sWinID;
		
#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3( username, out sError );
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString( username, out sError );
#endif
			if ( sUsername == null ) return -20;
		
#if _ENTERPRISE_
			sPassword = enc.Dx3( password, out sError );
#else
			sPassword = enc.DecryptString( password, out sError );
#endif
			if ( sPassword == null ) return -30;

#if _ENTERPRISE_
			sDiskID = enc.Dx3( DiskID, out sError );
#else
			sDiskID = enc.DecryptString( DiskID, out sError );
#endif
			if ( sDiskID == null ) return -40;

#if _ENTERPRISE_
			sWinID = enc.Dx3( WinID, out sError );
#else
			sWinID = enc.DecryptString( WinID, out sError );
#endif
			if ( sWinID == null ) return -50;

			int nClient = CheckClientVersion( nClientVer, out sError );
			if ( nClient == nClientVer )
			//if ( nClientVer > 2130 && nClientVer <= 2138 )
			{
				sError = "Please download and install newest Drumlin reader from\r\n\r\nhttp://www.drumlinsecurity.co.uk/Client/DrumlinSetup.zip";
				return -51;
			}

			//Before doing actual registration - check DiskID and WinID and 
			//if they don't match don't allow registration
			comCheck = new SqlCommand( "spCheckUser", conn );
			comCheck.Parameters.Add(new SqlParameter("@sUsername",	SqlDbType.VarChar)).Value = sUsername;
			comCheck.Parameters.Add(new SqlParameter("@sPassword",	SqlDbType.VarChar)).Value = sPassword;
			comCheck.Parameters.Add(new SqlParameter("@sWinID",		SqlDbType.VarChar)).Value = sWinID;
			comCheck.Parameters.Add(new SqlParameter("@sDiskID",	SqlDbType.VarChar)).Value = sDiskID;
			
			SqlParameter parResult1 = comCheck.Parameters.Add( "@nResult",	SqlDbType.Int );
			parResult1.Direction	= ParameterDirection.Output;
			parResult1.Value = -100;

			SqlParameter parUserType = comCheck.Parameters.Add( "@nUserType",	SqlDbType.Int );
			parUserType.Direction	= ParameterDirection.Output;
			parUserType.Value = 0;

			comCheck.CommandType = CommandType.StoredProcedure;
			
			int nID = comCheck.ExecuteNonQuery();
			try{
				nID = Convert.ToInt32(parResult1.Value);
				nUserType = Convert.ToInt32( parUserType.Value );
			} catch {
				sError = "There was error while checking user!";
				return -22;
			}
			
			//AddActivity( 0, 0, string.Format("spCheckUser:{0}", nID), out sError );
			
			if ( nID == -10 )
			{
				//user exists but has wrong IDs
				sError = "Username exists - please select a different username for registration!";
				return -23;
			}
			
			//Now, do the actual registration
			com = new SqlCommand( "spRegisterUser", conn );

			com.Parameters.Add(new SqlParameter("@sUsername",	SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sPassword",	SqlDbType.VarChar)).Value = sPassword;
			com.Parameters.Add(new SqlParameter("@sWinID",		SqlDbType.VarChar)).Value = sWinID;
			com.Parameters.Add(new SqlParameter("@sDiskID",		SqlDbType.VarChar)).Value = sDiskID;
			com.Parameters.Add(new SqlParameter("@nClientVer",	SqlDbType.Int)).Value = nClientVer;
			comCheck.Parameters.Add(new SqlParameter("@sOrganisation",	SqlDbType.VarChar)).Value = sOrganisation;
			
			SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
			parResult.Direction	= ParameterDirection.Output;
			parResult.Value = -60;

			com.CommandType = CommandType.StoredProcedure;
			
			int nRes = com.ExecuteNonQuery();
            try
            {
                nRes = Convert.ToInt32(parResult.Value);
            }
            catch
            {
                nRes = 0;
            }
			
			string sTemp = "";
			
			switch( nRes )
			{
			case -1:
				sError = "User not found!";
				break;
			
			case -2:
				sError = "Wrong WinID!";
				break;
			
			case -3:
				sError = "Wrong DiskID!";
				break;
				
			case 0:
//				sError = "Already registered";
				sTemp = GetRegCode( sUsername, sPassword, out sError );
				sError = sTemp;
				nRes = nID;
				break;
			
			default:
				//sError = "OK";
				sTemp = GetRegCode( sUsername, sPassword, out sError );
				sError = sTemp;
				break;
			}

			string sActivityDesc = "RegisterUserEx() "+sError;
			sTemp = "";
			AddActivity( 0, 0, ACTIVITY_REGISTER, sActivityDesc, out sTemp );

			return nRes;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -11;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
		
	}

	[WebMethod]
	public int SetDocumentData( int nDocID, byte[] data, out string sError )
	{
		sError = "";
		return SetDocumentDataEx( 0, nDocID, data, out sError );
	}

	/// <summary>
	/// Adds a new document information to the DB. If everything goes OK
	/// the data part (BLOB) will be uploaded to the DocData table
	/// </summary>
	/// <param name="nUserID"></param>
	/// <param name="nDocID"></param>
	/// <param name="data"></param>
	/// <param name="sError"></param>
	/// <returns></returns>
	[WebMethod]
	public int SetDocumentDataEx( int nUserID, int nDocID, byte[] data, out string sError )
	{
		sError = "";
		SqlConnection conn = null;

		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -1;
		}
		
		SqlCommand com = null;
		try
		{
			//document is too large - upload it in several parts
			int nTransmitted = 0;
			int nPart = 0;
			byte[] part = null;
			
			AddActivity( nUserID, nDocID, ACTIVITY_UPLOAD_DOC, string.Format("Uploading docID:{0} in part(s) by userID:{1}", nDocID, nUserID ), out sError );
			
			while ( nTransmitted < data.Length )
			{
				if ( data.Length - nTransmitted >= MAX_DATA_LEN )
					part = new byte[ MAX_DATA_LEN ];
				else
					part = new byte[ data.Length - nTransmitted ];
					
				for( int i=nPart*MAX_DATA_LEN, j=0; j<part.Length && i<data.Length; j++, i++ )
				{
					part[ j ] = data[ i ];
				}
				
				com = new SqlCommand( "spUploadDocumentDataByParts", conn );
				com.Parameters.Add(new SqlParameter("@nDocID",			SqlDbType.Int)).Value = nDocID;
				com.Parameters.Add(new SqlParameter("@nPartNo",			SqlDbType.Int)).Value = nPart;
				com.Parameters.Add(new SqlParameter("@dataPart",		SqlDbType.Image)).Value	= part;
				com.Parameters.Add(new SqlParameter("@nPartSize",		SqlDbType.Int)).Value = part.Length;

				SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
				parResult.Direction	= ParameterDirection.Output;
				parResult.Value = -1;

				com.CommandType = CommandType.StoredProcedure;
				
				int nRes = 0;
				com.ExecuteScalar();
				nRes = Convert.ToInt32( parResult.Value );
				
				if ( nRes >= 0 )
				{
					//Uploaded OK
					nTransmitted += part.Length;
					nPart ++;
				}
				else
				{
					sError = string.Format( 
						"There was an error while uploading document data!\r\nDocID={0}; Part={1}; PartSize={2}; TotalSize={3}",
						nDocID, nPart, part.Length, data.Length );
					AddActivity( nUserID, nDocID, ACTIVITY_UPLOAD_DOC, string.Format("ERROR: while uploading docID:{0} in {1} parts by userID:{2}", nDocID, nPart, nUserID ), out sError );
					return -1;
				}
			}

			AddActivity( nUserID, nDocID, ACTIVITY_UPLOAD_DOC, string.Format("Uploaded docID:{0} in {1} part(s) by userID:{2}", nDocID, nPart, nUserID ), out sError );
							
			return nPart;
		}
		catch ( Exception ex )
		{
			AddActivity( nUserID, nDocID, ACTIVITY_UPLOAD_DOC, string.Format("ERROR: while uploading docID:{0} by userID:{1} [{2}]", nDocID, nUserID, ex.Message ), out sError );
			sError = ex.Message + "\r\n" +ex.StackTrace;
			return -1;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}
/*
	[WebMethod]
	public bool SetPermissions( int[] aUserID, int[] aDocID, int nOpenCount, int nPrintCount, DateTime dtStart, DateTime dtExpiry, out string sError )
	{
		return SetPermissionsEx( aUserID, aDocID, nOpenCount, nPrintCount, dtStart, dtExpiry, 0, out sError );
	}
*/	
	/// <summary>
	/// Sets document/user permissions
	/// </summary>
	/// <param name="aUserID">Integer aray with all UserIDs</param>
	/// <param name="aDocID">Integer array with all DocIDs</param>
	/// <param name="nOpenCount">Number of allowed openings</param>
	/// <param name="nPrintCount">Number of allowed prinitngs</param>
	/// <param name="dtStart">Start date</param>
	/// <param name="dtExpiry">Expiry date</param>
	/// <param name="sError">Diagnostics</param>
	/// <returns>TRUE if OK</returns>
	[WebMethod]
	public bool SetPermissionsEx( int[] aUserID, int[] aDocID, int nOpenCount, int nPrintCount, DateTime dtStart, DateTime dtExpiry, int nUsePassword, out string sError )
	{
		sError = "";
		SqlConnection conn = null;

		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		try
		{
			for( int nUser=0; nUser<aUserID.Length; nUser++ )
			{
				for ( int nDoc=0; nDoc<aDocID.Length; nDoc++ )
				{
					com = new SqlCommand( "spSetPermission", conn );
					com.Parameters.Add(new SqlParameter("@nUserID",			SqlDbType.Int)).Value = aUserID[nUser];
					com.Parameters.Add(new SqlParameter("@nDocID",			SqlDbType.Int)).Value = aDocID[nDoc];
					com.Parameters.Add(new SqlParameter("@nOpenCount",		SqlDbType.Int)).Value = nOpenCount;
					com.Parameters.Add(new SqlParameter("@nPrintCount",		SqlDbType.Int)).Value = nPrintCount;
					com.Parameters.Add(new SqlParameter("@nPagesCount",		SqlDbType.Int)).Value = -1;
					com.Parameters.Add(new SqlParameter("@dtStart",			SqlDbType.DateTime)).Value = dtStart;
					com.Parameters.Add(new SqlParameter("@dtExpired",		SqlDbType.DateTime)).Value = dtExpiry;
					com.Parameters.Add(new SqlParameter("@nAskPassword",	SqlDbType.Int)).Value = nUsePassword;
					
					SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
					parResult.Direction	= ParameterDirection.Output;
					parResult.Value = -1;

					com.CommandType = CommandType.StoredProcedure;
					
					com.ExecuteNonQuery();
				}
				
/*Removed on 01.08.2007
				if (!SendNotification( aUserID[ nUser ], aDocID, nOpenCount, nPrintCount, -1, dtStart, dtExpiry, nUsePassword, out sError ))
				{
					return false;
				}
 */
			}
			
			return true;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}
	
	
	/// <summary>
	/// Method is identical to the SetPermissionsEx, except it doesn't send 
	/// e-mail notification to users who create permissions!
	/// </summary>
	/// <param name="aUserID"></param>
	/// <param name="aDocID"></param>
	/// <param name="nOpenCount"></param>
	/// <param name="nPrintCount"></param>
	/// <param name="dtStart"></param>
	/// <param name="dtExpiry"></param>
	/// <param name="nUsePassword"></param>
	/// <param name="sError"></param>
	/// <returns></returns>
	[WebMethod]
	public bool SetPermissions( int[] aUserID, int[] aDocID, int nOpenCount, int nPrintCount, int nPagesCount, bool bNotify,
			DateTime dtStart, DateTime dtExpiry, int nUsePassword, out string sError )
	{
		sError = "";
		SqlConnection conn = null;

		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		try
		{
			for( int nUser=0; nUser<aUserID.Length; nUser++ )
			{
				for ( int nDoc=0; nDoc<aDocID.Length; nDoc++ )
				{
					com = new SqlCommand( "spSetPermission", conn );
					com.Parameters.Add(new SqlParameter("@nUserID",			SqlDbType.Int)).Value = aUserID[nUser];
					com.Parameters.Add(new SqlParameter("@nDocID",			SqlDbType.Int)).Value = aDocID[nDoc];
					com.Parameters.Add(new SqlParameter("@nOpenCount",		SqlDbType.Int)).Value = nOpenCount;
					com.Parameters.Add(new SqlParameter("@nPrintCount",		SqlDbType.Int)).Value = nPrintCount;
					com.Parameters.Add(new SqlParameter("@nPagesCount",		SqlDbType.Int)).Value = nPagesCount;
					com.Parameters.Add(new SqlParameter("@dtStart",			SqlDbType.DateTime)).Value = dtStart;
					com.Parameters.Add(new SqlParameter("@dtExpired",		SqlDbType.DateTime)).Value = dtExpiry;
					com.Parameters.Add(new SqlParameter("@nAskPassword",	SqlDbType.Int)).Value = nUsePassword;
					
					SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
					parResult.Direction	= ParameterDirection.Output;
					parResult.Value = -1;

					com.CommandType = CommandType.StoredProcedure;
					
					com.ExecuteNonQuery();
				}
				
				if ( bNotify )
				{
					if (!SendNotification( aUserID[ nUser ], aDocID, nOpenCount, nPrintCount, nPagesCount,
							dtStart, dtExpiry, nUsePassword, out sError ))
					{
						return false;
					}
				}
			}
			
			return true;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}

	[WebMethod]
	public bool SetPermissions1( int[] aUserID, int[] aDocID, int nOpenCount, int nPrintCount, int nPagesCount, bool bNotify,
			DateTime dtStart, DateTime dtExpiry, int nUsePassword, int nAllowNetworkPrinting, out string sError )
	{
		sError = "";
		
		return SetPermissions2( aUserID, aDocID, nOpenCount, nPrintCount, nPagesCount, bNotify, dtStart, dtExpiry, nUsePassword, nAllowNetworkPrinting, 0, out sError );
	}
	
	/// <summary>
	/// Method is identical to the SetPermissions, except it sets "AllowNetworkPrinting" and "EnableClipboard"
	/// </summary>
	/// <param name="aUserID"></param>
	/// <param name="aDocID"></param>
	/// <param name="nOpenCount"></param>
	/// <param name="nPrintCount"></param>
	/// <param name="dtStart"></param>
	/// <param name="dtExpiry"></param>
	/// <param name="nUsePassword"></param>
	/// <param name="bNotify"></param>
	/// <param name="nAllowNetworkPrinting"></param>
	/// <param name="nEnableClipboard"></param>
	/// <param name="sError"></param>
	/// <returns></returns>
	[WebMethod]
	public bool SetPermissions2( int[] aUserID, int[] aDocID, int nOpenCount, int nPrintCount, int nPagesCount, bool bNotify,
			DateTime dtStart, DateTime dtExpiry, int nUsePassword, int nAllowNetworkPrinting, 
			int nEnableClipboard, out string sError )
	{
		sError = "";
		return SetPermissions4(aUserID, aDocID, nOpenCount, nPrintCount, nPagesCount, bNotify, dtStart, dtExpiry, nUsePassword, nAllowNetworkPrinting,
			nEnableClipboard, 1, -1, out sError);
	}

	/// <summary>
	/// Same as before (SetPermission2) but added "BlockGrabbers" flag
	/// </summary>
	/// <param name="aUserID"></param>
	/// <param name="aDocID"></param>
	/// <param name="nOpenCount"></param>
	/// <param name="nPrintCount"></param>
	/// <param name="nPagesCount"></param>
	/// <param name="bNotify"></param>
	/// <param name="dtStart"></param>
	/// <param name="dtExpiry"></param>
	/// <param name="nUsePassword"></param>
	/// <param name="nAllowNetworkPrinting"></param>
	/// <param name="nEnableClipboard"></param>
	/// <param name="sError"></param>
	/// <returns></returns>
	[WebMethod]
	public bool SetPermissions3( int[] aUserID, int[] aDocID, int nOpenCount, int nPrintCount, int nPagesCount, bool bNotify,
			DateTime dtStart, DateTime dtExpiry, int nUsePassword, int nAllowNetworkPrinting, 
			int nEnableClipboard, int nBlockGrabbers, out string sError )
	{
		sError = "";
		return SetPermissions4( aUserID, aDocID, nOpenCount, nPrintCount, nPagesCount, bNotify, dtStart, dtExpiry, nUsePassword, nAllowNetworkPrinting,
			nEnableClipboard, nBlockGrabbers, -1, out sError );
	}

	/// <summary>
	/// Identical to SetPermissions3 but with a new field "ExpiresAfter"!
	/// Added on 08.12.2010 by Harry
	/// </summary>
	/// <returns></returns>
	[WebMethod]
	public bool SetPermissions4( int[] aUserID, int[] aDocID, int nOpenCount, int nPrintCount, int nPagesCount, bool bNotify,
			DateTime dtStart, DateTime dtExpiry, int nUsePassword, int nAllowNetworkPrinting, 
			int nEnableClipboard, int nBlockGrabbers, int nExpiresAfter, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return false;
		}

		SqlCommand com = null;
		try
		{
			for (int nUser = 0; nUser < aUserID.Length; nUser++)
			{
				for (int nDoc = 0; nDoc < aDocID.Length; nDoc++)
				{
					com = new SqlCommand("spSetPermission", conn);
					com.Parameters.Add(new SqlParameter("@nUserID", SqlDbType.Int)).Value = aUserID[nUser];
					com.Parameters.Add(new SqlParameter("@nDocID", SqlDbType.Int)).Value = aDocID[nDoc];
					com.Parameters.Add(new SqlParameter("@nOpenCount", SqlDbType.Int)).Value = nOpenCount;
					com.Parameters.Add(new SqlParameter("@nPrintCount", SqlDbType.Int)).Value = nPrintCount;
					com.Parameters.Add(new SqlParameter("@nPagesCount", SqlDbType.Int)).Value = nPagesCount;
					com.Parameters.Add(new SqlParameter("@dtStart", SqlDbType.DateTime)).Value = dtStart;
					com.Parameters.Add(new SqlParameter("@dtExpired", SqlDbType.DateTime)).Value = dtExpiry;
					com.Parameters.Add(new SqlParameter("@nAskPassword", SqlDbType.Int)).Value = nUsePassword;
					com.Parameters.Add(new SqlParameter("@nAllowNetworkPrinting", SqlDbType.Int)).Value = nAllowNetworkPrinting;
					com.Parameters.Add(new SqlParameter("@nEnableClipboard", SqlDbType.Int)).Value = nEnableClipboard;
					com.Parameters.Add(new SqlParameter("@nBlockGrabbers", SqlDbType.Int)).Value = nBlockGrabbers;
					com.Parameters.Add(new SqlParameter("@nExpiresAfter", SqlDbType.Int)).Value = nExpiresAfter;
					SqlParameter parResult = com.Parameters.Add("@nResult", SqlDbType.Int);
					parResult.Direction = ParameterDirection.Output;
					parResult.Value = -1;

					com.CommandType = CommandType.StoredProcedure;

					com.ExecuteNonQuery();
				}

				if (bNotify)
				{
					if (!SendNotification(aUserID[nUser], aDocID, nOpenCount, nPrintCount, nPagesCount,
							dtStart, dtExpiry, nUsePassword, out sError))
					{
						return false;
					}
				}
			}

			return true;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if (conn != null) conn.Close();
		}
	}
	
	[WebMethod]
	public DataSet GetPermission( int nUserID, int nDocID, out string sError )
	{
		sError = "";
		SqlConnection conn = null;

		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		try
		{
			com = new SqlCommand( "spGetPermission", conn );
			com.Parameters.Add(new SqlParameter("@nUserID",	SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@nDocID",	SqlDbType.Int)).Value = nDocID;
			com.CommandType = CommandType.StoredProcedure;

			SqlDataAdapter da = new SqlDataAdapter();
			da.SelectCommand = com;
			
			DataSet ds = new DataSet("Permission_DS");
			da.Fill( ds, "Permission_DT" );
			
			return ds;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}

	/// <summary>
	/// Sends notification email to the user nUserID that at least one document is added to his/her
	/// list of downloadable documents.
	/// </summary>
	/// <param name="nUserID">User to which the email will be sent</param>
	/// <param name="aDocID">List of documents</param>
	/// <param name="nOpenCount">Opening count</param>
	/// <param name="nPrintCount">Print count</param>
	/// <param name="dtStart">From that data</param>
	/// <param name="dtExpiry">To date</param>
	private bool SendNotification( int nUserID, int[] aDocID, int nOpenCount, int nPrintCount, int nPageCount, DateTime dtStart, DateTime dtExpiry, int nUsePassword, out string sError )
	{
		SqlConnection conn = null;
		sError = "";
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand comUser = null;
		SqlCommand comDoc  = null;
		SqlDataReader drUser = null;
		SqlDataReader drDoc = null;
		bool bSendMail = false;
		string sEmail = "";
				
		string sText = "";
		
		try
		{
			comUser = new SqlCommand( "spGetUserByID1", conn );
			comUser.Parameters.Add(new SqlParameter("@nUserID",			SqlDbType.Int)).Value = nUserID;
			comUser.CommandType = CommandType.StoredProcedure;
			
			drUser = comUser.ExecuteReader();
			if ( drUser.Read() )
			{
				//sText = string.Format( "Dear {0},\r\n\r\n", drUser["Username"] );
				sText = string.Format( "For attn: Drumlin Reader user: {0}\r\n\r\n", drUser["Username"] );
				
				sText += "You have new Drumlin documents enabled for you. To retrieve any of these please start your Drumlin reader, check you have an active Internet connection and select File|Download to access these documents and select those you require.\r\n\r\n";
				
				sEmail = drUser["Email1"].ToString();
				
				drUser.Close();
				drUser = null;
				
				for ( int nDoc=0; nDoc<aDocID.Length; nDoc++ )
				{
					comDoc = new SqlCommand( "spGetDocumentByID", conn );
					comDoc.Parameters.Add(new SqlParameter("@nDocID",			SqlDbType.Int)).Value = aDocID[nDoc];

					comDoc.CommandType = CommandType.StoredProcedure;
					
					drDoc = comDoc.ExecuteReader();
					if ( drDoc.Read() )
					{
						string sPrint = "";
						string sOpen = "";
						
						if ( nPrintCount == -1 )
						{
							sPrint = "Yes: unlimited";
						}
						else if ( nPrintCount == 0 )
						{
							sPrint = "No";
						}
						else
						{
							sPrint = string.Format("Yes: #={0}", nPrintCount );
						}
						
						if ( nOpenCount == -1 )
						{
							sOpen = "Yes: unlimited";
						}
						else if ( nOpenCount == 0 )
						{
							sOpen = "No";
						}
						else
						{
							sOpen = string.Format("Yes: #={0}", nOpenCount );
						}
						
						sText += string.Format( 
"Title: {0}\r\nDescription: {1}\r\nAllowed to open: {2}\r\nAllowed to print: {3}\r\nStart date: {4}\r\nExpires: {5}\r\nNeeds password: {6}\r\n\r\n",
							drDoc["DocName"], drDoc["DocDescription"], 
							sOpen, sPrint, 
							dtStart.ToShortDateString(),
							dtExpiry.ToShortDateString(), 
							(nUsePassword==0?"No":"Yes") );
						
						try { sText += "\r\n\r\nServer: "+this.Server.MachineName; }
						catch {}
						
						bSendMail = true;
					}
					
					drDoc.Close();
					drDoc = null;
				}
			}

			if ( bSendMail && sEmail.Length > 0 )
			{
				return SendEmailEx( "drumlinsec@drumlinsecurity.co.uk", sEmail, sText, "New Drumlin Document Notification", out sError );
			}
			
			return true;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if ( drDoc != null ) drDoc.Close();
			if ( drUser != null ) drUser.Close();
			if ( conn != null ) conn.Close();
		}		
	}

	/// <summary>
	/// Delete a number of documents. The method calls a SP which also deletes
	/// document data and permissions linked to the documents.
	/// </summary>
	/// <param name="aDocID"></param>
	/// <param name="sError"></param>
	/// <returns></returns>
	[WebMethod]
	public bool DeleteDocuments( int[] aDocID, out string sError )
	{
		sError = "";
		SqlConnection conn = null;

		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		try
		{
			for ( int nDoc=0; nDoc<aDocID.Length; nDoc++ )
			{
				com = new SqlCommand( "spDeleteDocument", conn );
				com.Parameters.Add(new SqlParameter("@nDocID",			SqlDbType.Int)).Value = aDocID[nDoc];

				com.CommandType = CommandType.StoredProcedure;
				
				com.ExecuteNonQuery();
			}
			
			return true;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}
	
	private int GetLimitType( string sLimitType )
	{
		int nLastDot = sLimitType.LastIndexOf( '.' );
		string sTemp = sLimitType;
		
		if ( nLastDot != -1 )
		{
			sTemp = sLimitType.Substring( nLastDot );
		}
		
		sTemp = sTemp.ToUpper();
		
		if ( sTemp.CompareTo( ".PDF" ) == 0 )
		{
			return 1;
		}
		else if ( sTemp.CompareTo( ".DRMX" ) == 0 )
		{
			return 2;
		}
		else
		{
			return 1;
		}
	}
	
	[WebMethod]
	public bool CheckLimits( int nUserID, string sLimitType, out string sError )
	{
		sError = "";
		
		int nLimitType = GetLimitType( sLimitType );
		
		if ( nLimitType == -1 )
		{
			sError = "Wrong file type ("+sLimitType+")!";
			return false;
		}
		
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		try
		{
			com = new SqlCommand( "spCheckLimits", conn );
			com.Parameters.Add(new SqlParameter("@nUserID",			SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@nLimitType",		SqlDbType.Int)).Value = nLimitType;

			SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
			parResult.Direction	= ParameterDirection.Output;
			parResult.Value = -1;

			com.CommandType = CommandType.StoredProcedure;
			
			com.ExecuteNonQuery();
			
			int nResult = Convert.ToInt32( parResult.Value );
			
			//AddActivity( nUserID, 0, ACTIVITY_UPLOAD_DOC_INFO, string.Format("Result: {0} {1}", nResult, nLimitType ), out sError );
			
			if ( nResult == 0 )
			{
				return true;
			}
			else if ( nResult == 1 )
			{
				AddActivity(nUserID, 0, ACTIVITY_UPLOAD_DOC_INFO, string.Format("CheckLimits: Res:{0} UserID:{1} Limit:{2} File:{3}", nResult, nUserID, nLimitType, sLimitType), out sError);
				sError = "Publishing limit exceeded for UserID: "+nUserID.ToString();
			}
			else if ( nResult == 3 )
			{
				sError = "Publishing not allowed for UserID: "+nUserID.ToString();
			}
			else if ( nResult == 2 )
			{
				sError = "Publishing limit exceeded for company of UserID: "+nUserID.ToString();
			}
			else if ( nResult == 4 )
			{
				sError = "Publishing not allowed for company of UserID: "+nUserID.ToString();
			}
			else
			{
				sError = "Unknown error ("+nResult.ToString()+") while checking for publishing limits!";
			}
			
			return false;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}
	
	/// <summary>
	/// Sets document info.
	/// </summary>
	/// <param name="di">Document info</param>
	/// <param name="sError">Diagnostic text</param>
	/// <returns>if less then zero - error; Zero - existing record has been updated; greater then zero - new record</returns>
	[WebMethod]
	public int SetDocumentInfo( DocInfo di, out string sError )
	{
		sError = "";

		//check limits
		if ( !CheckLimits( di.m_nOwnerID, di.m_sFile, out sError ) )
		{
			//limits for this user were exceeded or not defined
			return -101;
		}

		SqlConnection conn = null;

		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -102;
		}
		
		
		SqlCommand com = null;
		try
		{
			com = new SqlCommand( "spAddNewDocument", conn );
			com.Parameters.Add(new SqlParameter("@nID",			SqlDbType.Int)).Value = di.m_nID;
			com.Parameters.Add(new SqlParameter("@sDocName",	SqlDbType.NVarChar)).Value = di.m_sName;
			com.Parameters.Add(new SqlParameter("@sDocDesc",	SqlDbType.NVarChar)).Value = di.m_sDesc;
			com.Parameters.Add(new SqlParameter("@sVersion",	SqlDbType.VarChar)).Value = di.m_sVersion;
			com.Parameters.Add(new SqlParameter("@nDocSize",	SqlDbType.Int)).Value = di.m_nDocSize;
			com.Parameters.Add(new SqlParameter("@sISBN",		SqlDbType.VarChar)).Value = di.m_sISBN;
			com.Parameters.Add(new SqlParameter("@nOwnerID",	SqlDbType.Int)).Value = di.m_nOwnerID;
			com.Parameters.Add(new SqlParameter("@nCreatorID",	SqlDbType.Int)).Value = di.m_nCreatorID;
			com.Parameters.Add(new SqlParameter("@bUSK",		SqlDbType.Bit)).Value = di.m_bUSK;
			com.Parameters.Add(new SqlParameter("@bMultiDL",	SqlDbType.Bit)).Value = di.m_bMultiDL;
			com.Parameters.Add(new SqlParameter("@bKeepVer",	SqlDbType.Bit)).Value = di.m_bKeepVer;
			com.Parameters.Add(new SqlParameter("@bMustBeOnline",	SqlDbType.Int)).Value = di.m_bMustBeOnline;
			com.Parameters.Add(new SqlParameter("@bMustBeRegistered",	SqlDbType.Int)).Value = di.m_bMustBeRegistered;
			com.Parameters.Add(new SqlParameter("@bAllowNetworkPrinting",	SqlDbType.Int)).Value = di.m_bAllowNetworkPrinting;
			com.Parameters.Add(new SqlParameter("@bEnableClipboard",	SqlDbType.Int)).Value = di.m_bEnableClipboard;
			com.Parameters.Add(new SqlParameter("@bBlockGrabbers",	SqlDbType.Int)).Value = di.m_bBlockGrabbers;
			com.Parameters.Add(new SqlParameter("@nDocState",	SqlDbType.Int)).Value = di.m_nDocState;
			com.Parameters.Add(new SqlParameter("@binHCKS",		SqlDbType.Binary)).Value = di.m_HCKS;
			com.Parameters.Add(new SqlParameter("@sDocPwd",		SqlDbType.NVarChar)).Value = di.m_sDocPwd;
			
			SqlParameter parDocID = com.Parameters.Add( "@nDocID",	SqlDbType.Int );
			parDocID.Direction	= ParameterDirection.Output;
			parDocID.Value = -1;

			SqlParameter parNewRec = com.Parameters.Add( "@nNewRecord",	SqlDbType.Int );
			parNewRec.Direction	= ParameterDirection.Output;
			parNewRec.Value = -1;

			com.CommandType = CommandType.StoredProcedure;
			
			int nRes = com.ExecuteNonQuery();
			int nDocID = Convert.ToInt32( parDocID.Value );
			int nNewRec= Convert.ToInt32( parNewRec.Value );
			
			string sActivityDesc = "";
			
			if ( nDocID == -5 )
			{
				sActivityDesc = 
				string.Format( "Error while uploading doc {0} {1} by userID:{2}: User doesn't exist!", di.m_sName, di.m_nID, di.m_nOwnerID );
				sError = "User doesn't exist!";
			}
			else if ( nDocID == -6 )
			{
				sActivityDesc = 
				string.Format( "Error while uploading doc {0} {1} by userID:{2}: User account expired!", di.m_sName, di.m_nID, di.m_nOwnerID );
				sError = "User account expired!";
			}
			else if ( nDocID < 0 )
			{
				sActivityDesc = 
				string.Format( "Error while uploading doc {0} {1} by userID:{2}", di.m_sName, di.m_nID, di.m_nOwnerID );
			}
			else if ( nNewRec == 0 )
			{
				sActivityDesc = 
				string.Format( "DocumentInfo {0} {1} updated by userID:{2}", di.m_sName, nDocID, di.m_nOwnerID );
			}
			else
			{
				sActivityDesc = 
				string.Format( "DocumentInfo {0} {1} added by userID:{2}", di.m_sName, nDocID, di.m_nOwnerID );
			}
			
			AddActivity( di.m_nOwnerID, nDocID, ACTIVITY_UPLOAD_DOC_INFO, sActivityDesc, out sError );
			
			return nDocID;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -103;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}
/*
	[WebMethod]
	public byte[] GetDocumentData( int nUserID, int nDocumentID, out string sError )
	{
		sError = "";
		
		SqlConnection conn = null;
		SqlDataReader	dr	= null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		SqlCommand com1 = null;
		SqlDataReader dr1 = null;
		SqlDataReader dr2 = null;
		
		try
		{
			//first - get user's winID and diskID what will be needed for encryption
			com1 = new SqlCommand( "spGetUserByID", conn );
			com1.Parameters.Add(new SqlParameter("@nID", SqlDbType.Int)).Value = nUserID;
			com1.CommandType = CommandType.StoredProcedure;
			dr1 = com1.ExecuteReader();
			dr1.Read();
			Object oResult = dr1.GetValue( 0 );
			
			if ( oResult == DBNull.Value )
			{
				sError = "Invalid user! Cannot download document.";
				return null;
			}
			
			com = new SqlCommand( "spGetDocumentData", conn );
			com.Parameters.Add(new SqlParameter("@nDocumentID",	SqlDbType.Int)).Value = nDocumentID;

			com.CommandType = CommandType.StoredProcedure;
			
			dr = com.ExecuteReader();
			dr.Read();
			
			oResult = dr.GetValue( 0 );
			if ( oResult != DBNull.Value )
			{
				byte[] myData = (byte[])oResult;
				
				sError = string.Format( "DEBUG oResult={0} len={1}", oResult.ToString(), myData.Length );
				return null;
				
				if ( myData.Length > 0 )
				{
					string sDiskID = dr1[ "DiskID" ].ToString();
					string sWinID  = dr1[ "WinID" ].ToString();
					int nClientID  = Convert.ToInt32( dr1[ "ClientID" ] );
					Encryption.DocEncryption enc = new Encryption.DocEncryption( sDiskID, sWinID, nClientID );
					return enc.Encrypt( myData, out sError );
				}
			}

			sError = "DEBUG!!!";
			return null;

			//if I'm here that means that an error occured while trying to encrypt one-part data
			//try with multi-part...

			//since the data is NULL - try to download the data from DocData table
			//check number of document parts
			SqlCommand com2 = null;
			com2 = new SqlCommand( "spGetNumberOfDocParts", conn );
			com2.Parameters.Add(new SqlParameter("@nDocumentID",	SqlDbType.Int)).Value = nDocumentID;
			SqlParameter parCount = com2.Parameters.Add( "@nCount",	SqlDbType.Int );
			parCount.Direction	= ParameterDirection.Output;
			parCount.Value = -1;

			SqlParameter parSize = com2.Parameters.Add( "@nTotalSize",	SqlDbType.Int );
			parSize.Direction	= ParameterDirection.Output;
			parSize.Value = -1;

			com2.CommandType = CommandType.StoredProcedure;
			object oRes = com2.ExecuteScalar();
			int nCount = Convert.ToInt32( parCount.Value );
			int nSize =  Convert.ToInt32( parSize.Value );
			if ( nCount != 0 && nSize != 0 )
			{
				byte[] doc = new byte[nSize];
				int nTransferred = 0;
				int nPart = 0;
				int nPartSize = 0;
				byte[] part = null;
				
				while( nTransferred < nSize )
				{
					SqlCommand com3 = new SqlCommand( "spGetDocumentDataByPart", conn );
					com3.Parameters.Add( new SqlParameter( "@nDocumentID", SqlDbType.Int)).Value = nDocumentID;
					com3.Parameters.Add( new SqlParameter( "@nPart", SqlDbType.Int)).Value = nPart;
					
					dr2 = com3.ExecuteReader();
					dr2.Read();
					
					Object oSize = dr2.GetValue( 1 );
					Object oData = dr2.GetValue( 0 );
					if ( oSize == DBNull.Value || oData == DBNull.Value )
					{
						sError = "Download error (1)!";
						return null;
					}
					
					nPartSize = Convert.ToInt32( oSize );
					part = (byte[])oData;
					
					for( int i=nTransferred, j=0; i<nSize && j<nPartSize; i++, j++ )
					{
						doc[ i ] = part[ j ];
					}
					
					nPart++;
					nTransferred += nPartSize;
				}
				
				string sDiskID = dr1[ "DiskID" ].ToString();
				string sWinID  = dr1[ "WinID" ].ToString();
				int nClientID  = Convert.ToInt32( dr1[ "ClientID" ] );
				Encryption.DocEncryption enc = new Encryption.DocEncryption( sDiskID, sWinID, nClientID );
				return enc.Encrypt( doc, out sError );
			}
			else
			{
				sError = "Document data doesn't exist!";
				return null;
			}
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally
		{
			if ( dr2 != null ) dr2.Close();
			if ( dr1 != null ) dr1.Close();
			if ( dr != null ) dr.Close();
			if ( conn != null) conn.Close();
		}
	}
		
*/		
	[WebMethod]
	public DocInfo GetDocumentInfo( int nDocumentID, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		
		try
		{
			com = new SqlCommand( "spGetDocumentInfo", conn );
			com.Parameters.Add(new SqlParameter("@nDocumentID",	SqlDbType.Int)).Value = nDocumentID;

			SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
			parResult.Direction	= ParameterDirection.Output;
			parResult.Value = -1;

			com.CommandType = CommandType.StoredProcedure;
			SqlDataReader reader = com.ExecuteReader();//GMSData.ExecuteSprocQueryReader(com);
			
			if ( reader.Read() )
			{
				int nResult = Convert.ToInt32( parResult.Value );
				
				if ( nResult == -3 )
				{
					sError = "Wrong document ID!";
					return null;
				}
				
				DocInfo di = new DocInfo();
				
				di.m_nID			= Convert.ToInt32( reader[ "ID" ] );
				di.m_nOwnerID		= Convert.ToInt32( reader[ "OwnerID" ] );
				di.m_nCreatorID		= Convert.ToInt32( reader[ "CreatorID"] );
				di.m_sName			= reader[ "DocName" ].ToString();
				di.m_sDesc			= reader[ "DocDescription" ].ToString();
				di.m_datePublished	= Convert.ToDateTime( reader[ "PubDate" ] );
				di.m_sVersion		= reader[ "Version" ].ToString();
				di.m_dateUploaded	= Convert.ToDateTime( reader[ "UploadDate" ] );
				di.m_nDocSize		= Convert.ToInt32( reader[ "DocSize" ] );
				di.m_sISBN			= reader[ "ISBN" ].ToString();
				di.m_nDocState		= Convert.ToInt32( reader["DocState"] );

				return di;
			}
			else
			{
				sError = "Wrong document ID!";
				return null;
			}
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return null;
		}
		finally
		{
			conn.Close();
		}
	}
	
	[WebMethod]
	public double CheckDocumentVersion( string sDocName, double dVersion, out string sError )
	{
		sError = "";
		SqlConnection connection = null;
		
		try 
		{
			connection = GetConnection( out sError);
			connection.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -1.0;
		}
		
		SqlCommand com = null;

		try
		{
			//int nResult = 0;

			//get counters and dates to the dataset
			com = new SqlCommand("spCheckDocument", connection);
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add(new SqlParameter("@sDocumentName", SqlDbType.VarChar)).Value = sDocName;
			com.Parameters.Add(new SqlParameter("@dVersion", SqlDbType.Float)).Value = dVersion;
			
			SqlParameter param = com.Parameters.Add("@dResult", SqlDbType.Float);
			param.Direction = ParameterDirection.Output;
			
			com.ExecuteNonQuery();

			try
			{
				double dVer = Convert.ToDouble( param.Value );
				
				return dVer;
			}
			catch 
			{
				sError = "There was error while checking user!";
				return -1.0;
			}
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -1.0;
		}
		finally
		{
			if (connection != null)
			{
				connection.Close();
				connection = null;
			}
		}
	}
	
	
	/// <summary>
	/// Returns data set with document data and other counters encoded with
	/// USK. Note that the document data in the dataset is encoded with HCK.
	/// This method prepares dataset completely with counters, dates and BLOB
	/// Since there was some problems with "OutOfMemory" exception on the server
	/// the decision was made to prepare dataset, encrypt it with USK and leave to
	/// the client to download the document BLOB part-by-part and store it to the
	/// dataset locally (see GetDocumentEx)
	/// </summary>
	/// <param name="nDocumentID">Document ID</param>
	/// <param name="nUserID">User ID</param>
	/// <param name="sError">Diagnostic text</param>
	/// <returns>null if error, encoded DataSet otherwise</returns>
	[WebMethod]
	public byte[] GetDocument( int nDocumentID, int nUserID, out string sError )
	{
		sError = "";
		SqlConnection connection = null;
		
		try 
		{
			connection = GetConnection( out sError);
			connection.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;

		try
		{
			//int nResult = 0;

			if ( nUserID != 0 )
			{
				if ( CheckTransaction( nUserID, nDocumentID, out sError ) )
				{
					//if the transaction exists - don't allow another one!
					sError = "Document cannot be downloaded more then once.\r\nPlease contact someone!";
					return null;
				}
			}
			
			//get counters and dates to the dataset
			com = new SqlCommand("spDocumentInfo", connection);
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add(new SqlParameter( "@nDocumentID", nDocumentID ));
			com.Parameters.Add(new SqlParameter( "@nUserID", nUserID ));
			SqlParameter param = com.Parameters.Add("@nResult", SqlDbType.Int);
			param.Direction = ParameterDirection.Output;

			SqlDataAdapter da = new SqlDataAdapter(com);
			DataSet ds = new DataSet();
			da.Fill(ds, "DocInfo");
			
			connection.Close();
			connection = null;
			
			//check if data size iz zero
			int nSize = Convert.ToInt32( ds.Tables[0].Rows[0]["DocSize"] );
			if ( nSize == 0 )
			{
				//document size in Docs table is zero - what might mean that
				//the document is stored in DocData table
				byte[] dataDocument = GetDocumentBytes( nDocumentID, out sError );
				if ( dataDocument == null )
				{
					//some kind of error occurred while trying to 
					//fetch reconstructed multi-part document
					return null;
				}
				
				ds.Tables[0].Rows[0]["DocSize"] = dataDocument.Length;
				ds.Tables[0].Rows[0]["DocData"] = dataDocument;
				ds.Tables[0].AcceptChanges();
			}
			
			//now I've got dataset - need to encode it with USK
			byte[] buffer = EncodeDataSet( ds, nUserID, false, out sError );

			if ( nUserID != 0 && buffer != null )
			{
				//Update transaction history table
				AddTransaction( nDocumentID, nUserID, 1, out sError );
			}

			return buffer;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return null;
		}
		finally
		{
			if (connection != null)
			{
				connection.Close();
				connection = null;
			}
		}
	}

	/// <summary>
	/// Returns data set with document data and other counters encoded with
	/// USK. Unlike GetDocument, this method prepares complete dataset only if the document
	/// is smaller then 1MB, otherwise it's necessary that client calls
	/// GetDocumentPart method to download document part-by-part and
	/// prepare the dataset locally. This is because the server has
	/// problems with preparing bigger datasets!
	/// 
	/// Harry 29.01.2007
	/// </summary>
	/// <param name="nDocumentID">Document ID</param>
	/// <param name="nUserID">User ID</param>
	/// <param name="sError">Diagnostic text</param>
	/// <returns>null if error, encoded DataSet otherwise</returns>
	[WebMethod]
	public byte[] GetDocumentEx( int nDocumentID, int nUserID, out string sError )
	{
		sError = "";
		SqlConnection connection = null;
		
		try 
		{
			connection = GetConnection( out sError);
			connection.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message+"....";
			return null;
		}
		
		SqlCommand com = null;

		try
		{
			//int nResult = 0;

			if ( nUserID != 0 )
			{
				if ( CheckTransaction( nUserID, nDocumentID, out sError ) )
				{
					//if the transaction exists - don't allow another one!
					sError = "Document cannot be downloaded more then once.\r\nPlease contact someone!";
					return null;
				}
			}

			//get counters and dates to the dataset
			com = new SqlCommand("spDocumentInfo", connection);
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add(new SqlParameter( "@nDocumentID", nDocumentID ));
			com.Parameters.Add(new SqlParameter( "@nUserID", nUserID ));
			SqlParameter param = com.Parameters.Add("@nResult", SqlDbType.Int);
			param.Direction = ParameterDirection.Output;

			SqlDataAdapter da = new SqlDataAdapter(com);
			DataSet ds = new DataSet();
			da.Fill(ds, "DocInfo");

			connection.Close();
			connection = null;

			//now I've got dataset - need to encode it with USK
			byte[] buffer = EncodeDataSet( ds, nUserID, true, out sError );

			return buffer;
		}
		catch (Exception ex)
		{
			sError = "----"+ex.Message;//+"\r\n\r\n"+ex.StackTrace+"\r\n\r\n"+sTemp;
			return null;
		}
		finally
		{
			if (connection != null)
			{
				connection.Close();
				connection = null;
			}
		}
	}

	/// <summary>
	/// Old style method - uses HCK instead of PDK encryption. Calls GetDocumentUninitialisedEx
	/// </summary>
	/// <param name="nDocumentID"></param>
	/// <param name="nUserID"></param>
	/// <param name="sError"></param>
	/// <returns></returns>
	[WebMethod]
	public byte[] GetDocumentUninitialised( int nDocumentID, int nUserID, out string sError )
	{
		sError = "";
		return GetDocumentUninitialisedEx( nDocumentID, nUserID, false, out sError );
	}
	
	/// <summary>
	/// Returns data set with document data and other counters encoded with
	/// USK. Unlike GetDocument, this method prepares complete dataset only if the document
	/// is smaller then 1MB, otherwise it's necessary that client calls
	/// GetDocumentPart method to download document part-by-part and
	/// prepare the dataset locally. This is because the server has
	/// problems with preparing bigger datasets!
	/// 
	/// This is almost identical method to GetDocumentEx
	/// except it doesn't use USK for encryption and doesn't 
	/// add transaction history entry
	/// 
	/// Harry	02.03.2007
	///			21.04.2011 - added PDK encryption support
	/// 
	/// </summary>
	/// <param name="nDocumentID">Document ID</param>
	/// <param name="nUserID">User ID</param>
	/// <param name="bPDK">Use new PDK encryption or HCK</param>
	/// <param name="sError">Diagnostic text</param>
	/// <returns>null if error, encoded DataSet otherwise</returns>
	[WebMethod]
	public byte[] GetDocumentUninitialisedEx( int nDocumentID, int nUserID, bool bPDK, out string sError )
	{
		sError = "";
		SqlConnection connection = null;
		
		try 
		{
			connection = GetConnection( out sError);
			connection.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message+"....";
			return null;
		}
		
		SqlCommand com = null;

		try
		{
			//int nResult = 0;

			//get counters and dates to the dataset
			com = new SqlCommand("spDocumentInfo", connection);
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add(new SqlParameter( "@nDocumentID", nDocumentID ));
			com.Parameters.Add(new SqlParameter( "@nUserID", nUserID ));
			SqlParameter param = com.Parameters.Add("@nResult", SqlDbType.Int);
			param.Direction = ParameterDirection.Output;

			SqlDataAdapter da = new SqlDataAdapter(com);
			DataSet ds = new DataSet();
			da.Fill(ds, "DocInfo");

			connection.Close();
			connection = null;

			//now I've got dataset - need to encode it with USK
			byte[] buffer = EncodeDataSet( ds, 0, bPDK, out sError );

			return buffer;
		}
		catch (Exception ex)
		{
			sError = "----"+ex.Message;//+"\r\n\r\n"+ex.StackTrace+"\r\n\r\n"+sTemp;
			return null;
		}
		finally
		{
			if (connection != null)
			{
				connection.Close();
				connection = null;
			}
		}
	}

	/// <summary>
	/// Downloads only one part of the document from the DocData table.
	/// </summary>
	/// <param name="nDocumentID">Document ID</param>
	/// <param name="nPartNo">Document part number</param>
	/// <param name="nUserID">UserID</param>
	/// <param name="password">USK encrypted password</param>
	/// <param name="bAddTransaction">Add transaction record or not</param>
	/// <param name="sError">Diagnostic error</param>
	/// <returns>null if error, part of the document otherwise</returns>
	[WebMethod]
	public byte[] GetDocumentPart( int nDocumentID, int nUserID, byte[] password, int nPartNo, bool bAddTransaction, out string sError )
	{
		sError = "";
	
		int nEncryptionType = 0;
		
		return GetDocumentPartEx( nDocumentID, nUserID, password, nPartNo, bAddTransaction, out nEncryptionType, out sError );
	}

	[WebMethod]
	public byte[] GetDocumentPartEx(int nDocumentID, int nUserID, byte[] password, int nPartNo, bool bAddTransaction, out int nEncryptionType, out string sError)
	{
		sError = "";
		nEncryptionType = 0;

		//in order to be secure, the user must supply his userID and USK encrypted password to avoid other people
		//to pretend they're this user and download the document.
		if (CheckPassword(nUserID, password, true, out sError) == false)//try with PDK encryption
		{
			if (CheckPassword(nUserID, password, false, out sError) == false)//then with old encryption
			{
				return null;
			}
		}

		//password is OK, get the document part
		byte[] data = GetDocumentPart(nDocumentID, nPartNo, out nEncryptionType, out sError);

		if (data != null && bAddTransaction)
		{
			AddTransaction(nDocumentID, nUserID, 1, out sError);
		}

		return data;
	}

	/// <summary>
	/// PRIVATE method for retrieving a part of the document from the DocData table
	/// </summary>
	/// <param name="nDocumentID">Document ID</param>
	/// <param name="nPartNo">Part number</param>
	/// <param name="sError">Diag text</param>
	/// <returns>null if error, BLOB otherwise</returns>
	private byte[] GetDocumentPart( int nDocumentID, int nPartNo, out int nEncryptionType, out string sError )
	{
		sError = "";
		nEncryptionType = 0;
		
		SqlConnection connection = null;
		SqlDataReader	dr	= null;
		
		try 
		{
			connection = GetConnection( out sError);
			connection.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;

		try
		{
			//int nResult = 0;
			com = new SqlCommand( "spGetDocumentDataByPart", connection );

			com.Parameters.Add( new SqlParameter( "@nDocumentID", SqlDbType.Int)).Value = nDocumentID;
			com.Parameters.Add( new SqlParameter( "@nPart", SqlDbType.Int)).Value = nPartNo;
			com.CommandType = CommandType.StoredProcedure;
			
			dr = com.ExecuteReader();
			
			dr.Read();
			
			Object oSize = dr.GetValue( 1 );
			Object oData = dr.GetValue( 0 );
			Object oEncType = dr.GetValue( 2 );//28.4.2011
			
			if ( oSize == DBNull.Value || oData == DBNull.Value )
			{
				sError = "Download error while downloading part "+nPartNo.ToString()+"!";
				return null;
			}
			
			int nPartSize = Convert.ToInt32( oSize );
			byte[] part = (byte[])oData;
			try{ nEncryptionType=Convert.ToInt32( oEncType ); } catch { nEncryptionType = 0; }
			
			return part;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return null;
		}
		finally
		{
			if ( dr != null )
			{
				dr.Close();
				dr = null;
			}
			if (connection != null)
			{
				connection.Close();
				connection = null;
			}
		}
	}
	
	/// <summary>
	/// Gets user's password from the DB and compares it with the encrypted password
	/// supplied by that user.
	/// </summary>
	/// <param name="nUserID">userID</param>
	/// <param name="password">USK encrypted password</param>
	/// <param name="sError">Diagnostic text</param>
	/// <returns>TRUE if OK</returns>
	private bool CheckPassword( int nUserID, byte[] password, bool bPDK, out string sError )
	{
		sError = "";
		
		string sDiskID = "";
		string sWinID  = "";
		
		if ( !GetIDs( nUserID, out sDiskID, out sWinID, out sError ) )
		{
			//something wrong with IDs
			return false;
		}
		
		string sPassword = "";
		
#if _ENTERPRISE_
		Encryption.E2 denc = new Encryption.E2( sDiskID, sWinID, nUserID );
		string sPassword = denc.Dx3( password, out sError );
#else
		
		if ( bPDK )
		{
			Encryption.PDKEncryption denc = new Encryption.PDKEncryption();
			byte[] data = denc.Decrypt( sDiskID, sWinID, nUserID, password, out sError);
			if ( data == null ) return false;
			sPassword = denc.GetString( data );
		}
		else
		{
			Encryption.DocEncryption denc = new Encryption.DocEncryption( sDiskID, sWinID, nUserID );
			sPassword = denc.DecryptString( password, out sError );
		}
#endif
		if ( sPassword == null )
		{
			//there was an error while trying to decrypt password
			return false;
		}
		
		//if I'm here, that means that I was able to decrypt password
		//Do I still have to compare the password with this user pwd???
		return true;
	}
	
	/// <summary>
	/// Returns document bytes from the DB. Note - BLOB is encrypted with HCK
	/// 
	/// Called by GetDocument
	/// 
	/// </summary>
	/// <param name="nDocumentID">Document ID</param>
	/// <param name="sError">Diagnostic text</param>
	/// <returns>null if error, BLOB otherwise</returns>
	private byte[] GetDocumentBytes( int nDocumentID, out string sError )
	{
		sError = "";
		
		SqlConnection conn = null;
		SqlDataReader	dr	= null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		try
		{
			//check number of document parts
			SqlCommand com2 = null;
			com2 = new SqlCommand( "spGetNumberOfDocParts", conn );
			com2.Parameters.Add(new SqlParameter("@nDocumentID",	SqlDbType.Int)).Value = nDocumentID;
			SqlParameter parCount = com2.Parameters.Add( "@nCount",	SqlDbType.Int );
			parCount.Direction	= ParameterDirection.Output;
			parCount.Value = -1;

			SqlParameter parSize = com2.Parameters.Add( "@nTotalSize",	SqlDbType.Int );
			parSize.Direction	= ParameterDirection.Output;
			parSize.Value = -1;

			com2.CommandType = CommandType.StoredProcedure;

			object oRes = com2.ExecuteScalar();
			int nCount = Convert.ToInt32( parCount.Value );
			int nSize =  Convert.ToInt32( parSize.Value );
			if ( nCount != 0 && nSize != 0 )
			{
				byte[] doc = new byte[nSize];
				int nTransferred = 0;
				int nPart = 0;
				int nPartSize = 0;
				byte[] part = null;

				while( nTransferred < nSize )
				{
					SqlCommand com3 = new SqlCommand( "spGetDocumentDataByPart", conn );

					com3.Parameters.Add( new SqlParameter( "@nDocumentID", SqlDbType.Int)).Value = nDocumentID;
					com3.Parameters.Add( new SqlParameter( "@nPart", SqlDbType.Int)).Value = nPart;
					com3.CommandType = CommandType.StoredProcedure;
					
					dr = com3.ExecuteReader();
					
					dr.Read();
					
					Object oSize = dr.GetValue( 1 );
					Object oData = dr.GetValue( 0 );
					if ( oSize == DBNull.Value || oData == DBNull.Value )
					{
						sError = "Download error while composing multi-part document (1)!";
						return null;
					}
					
					nPartSize = Convert.ToInt32( oSize );
					part = (byte[])oData;
					
					for( int i=nTransferred, j=0; i<nSize && j<nPartSize; i++, j++ )
					{
						doc[ i ] = part[ j ];
					}
					
					nPart++;
					nTransferred += nPartSize;
					dr.Close();
					dr = null;
				}
				
				return doc;
			}
			else
			{
				sError = "Download error while composing multi-part document: Document data doesn't exist!";
				return null;
			}
		}
		catch( Exception ex )
		{
			sError = ex.Message;// + "\r\n"+ ex.StackTrace;
			return null;
		}
		finally
		{
			if ( dr != null ) dr.Close();
			if ( conn != null) conn.Close();
		}
	}
	
	private byte[] EncodeDataSet( DataSet ds, int nUserID, bool bUsePDK, out string sError )
	{
		sError = "";
		string sDiskID = "";
		string sWinID  = "";
		
		if ( nUserID != 0 )
		{
			if ( GetIDs( nUserID, out sDiskID, out sWinID, out sError ) == false )
			{
				return null;
			}
		}

		MemoryStream mst = null;
		BinaryFormatter bf = null;
		try
		{
			mst = new MemoryStream();
			bf = new BinaryFormatter();
			
			bf.Serialize( mst, ds );
			
			//now I've got serialised datasource with document and doc info
			//encrypt the document by using this user's key!
			byte[] encData = null;
			
			if ( nUserID == 0 )
			{
				//if this is a not-registered user use ordinary encryption
#if _ENTERPRISE_
				Encryption.E1 denc = new Encryption.E1();
				encData = denc.Ex1( mst.ToArray(), out sError );
#else
				if ( !bUsePDK )
				{
					Encryption.MyEncryption denc = new Encryption.MyEncryption();
					encData = denc.Encrypt( mst.ToArray(), out sError );
				}
				else
				{
					Encryption.PDKEncryption denc = new Encryption.PDKEncryption();
					encData = denc.Encrypt( mst.ToArray(), out sError );
				}
#endif
			}
			else
			{
				//registered user - use normal encryption
#if _ENTERPRISE_
				Encryption.E2 denc = new Encryption.E2( sDiskID, sWinID, nUserID );
				encData = denc.Ex1( mst.ToArray(), out sError );
#else
				if ( !bUsePDK )
				{
					Encryption.DocEncryption denc = new Encryption.DocEncryption( sDiskID, sWinID, nUserID );
					encData = denc.Encrypt( mst.ToArray(), out sError );
				}
				else
				{
					Encryption.PDKEncryption denc = new Encryption.PDKEncryption();
					encData = denc.Encrypt( sDiskID, sWinID, nUserID, mst.ToArray(), out sError);
				}
#endif
			}
			
			return encData;
		}
		catch( Exception ex1 )
		{
			sError = "->"+ex1.Message;//+"\r\n\r\n"+ex1.StackTrace;
			return null;
		}
		finally
		{
			if ( mst != null ) mst.Close();
		}

	}
	
	private byte[] EncodeArray( object[] myArray, int nUserID, out string sError )
	{
		sError = "";
		string sDiskID = "";
		string sWinID  = "";
		
		if ( nUserID != 0 )
		{
			if ( GetIDs( nUserID, out sDiskID, out sWinID, out sError ) == false )
			{
				return null;
			}
		}

		MemoryStream mst = null;
		BinaryFormatter bf = null;
		try
		{
			mst = new MemoryStream();
			bf = new BinaryFormatter();
			
			bf.Serialize( mst, myArray );
			
			//now I've got serialised datasource with document and doc info
			//encrypt the document by using this user's key!
			byte[] encData = null;
			
			if ( nUserID == 0 )
			{
				//if this is an un-registered user use ordinary encryption
#if _ENTERPRISE_
				Encryption.E1 denc = new Encryption.E1();
				encData = denc.Ex1( mst.ToArray(), out sError );
#else
				Encryption.MyEncryption denc = new Encryption.MyEncryption();
				encData = denc.Encrypt( mst.ToArray(), out sError );
#endif
			}
			else
			{
				//registered user - use normal encryption
#if _ENTERPRISE_
				Encryption.E2 denc = new Encryption.E2( sDiskID, sWinID, nUserID );
				encData = denc.Ex1( mst.ToArray(), out sError );
#else
				Encryption.DocEncryption denc = new Encryption.DocEncryption( sDiskID, sWinID, nUserID );
				encData = denc.Encrypt( mst.ToArray(), out sError );
#endif
			}
			
			return encData;
		}
		catch( Exception ex1 )
		{
			sError = "WS: "+ex1.Message;//+"\r\n\r\n"+ex1.StackTrace;
			return null;
		}
		finally
		{
			if ( mst != null ) mst.Close();
		}

	}

	[WebMethod]
	public bool AddTransaction( int nDocumentID, int nUserID, int nActionCode, out string sError )
	{
		sError = "";
		SqlConnection connection = null;

		try 
		{
			connection = GetConnection( out sError);
			connection.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}

		try
		{
			SqlCommand com = new SqlCommand( "spAddTransaction", connection );
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add(new SqlParameter("@nUserID",			SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@nDocumentID",		SqlDbType.Int)).Value = nDocumentID;
			com.Parameters.Add(new SqlParameter("@nActionCode",		SqlDbType.Int)).Value = nActionCode;

			com.ExecuteNonQuery();
			return true;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if (connection != null)
			{
				connection.Close();
				connection = null;
			}
		}
	}

	private bool AddActivity( int nUserID, int nDocID, int nActivityID, string sDesc, out string sError )
	{
		sError = "";
		SqlConnection connection = null;

		try 
		{
			connection = GetConnection( out sError);
			connection.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		
		string sIP = "";
		try {
			sIP = HttpContext.Current.Request.ServerVariables["REMOTE_ADDR"].ToString();
		} catch {
		}


		try
		{
			SqlCommand com = new SqlCommand( "spAddActivity", connection );
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add(new SqlParameter("@nUserID",			SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@nDocID",			SqlDbType.Int)).Value = nDocID;
			com.Parameters.Add(new SqlParameter("@nActivityID",		SqlDbType.Int)).Value = nActivityID;
			com.Parameters.Add(new SqlParameter("@sDesc",			SqlDbType.VarChar)).Value = sDesc;
			com.Parameters.Add(new SqlParameter("@sIP", 			SqlDbType.VarChar)).Value = sIP;

			com.ExecuteNonQuery();
			return true;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if (connection != null)
			{
				connection.Close();
				connection = null;
			}
		}
	}

	/// <summary>
	/// Adds an order transaction to the DB
	/// </summary>
	/// <param name="nUserID"></param>
	/// <param name="nTransactionID"></param>
	/// <param name="sCode"></param>
	/// <param name="sText"></param>
	/// <param name="sError"></param>
	/// <returns>true if OK</returns>
	[WebMethod]
	public bool AddOrder( int nUserID, int nTransactionID, string sCode, string sText, out string sError )
	{
		sError = "";
		SqlConnection connection = null;

		try 
		{
			connection = GetConnection( out sError);
			connection.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}

		try
		{
			SqlCommand com = new SqlCommand( "spAddOrderTransaction", connection );
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add(new SqlParameter("@nUserID",			SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@nTransID",		SqlDbType.Int)).Value = nTransactionID;
			com.Parameters.Add(new SqlParameter("@sTransCode",		SqlDbType.VarChar)).Value = sCode;
			com.Parameters.Add(new SqlParameter("@sTransText",		SqlDbType.VarChar)).Value = sText;

			com.ExecuteNonQuery();
			return true;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if (connection != null)
			{
				connection.Close();
				connection = null;
			}
		}
	}

	private bool CheckTransaction( int nUserID, int nDocumentID, out string sError )
	{
		sError  = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		
		try 
		{
			com = new SqlCommand( "spCheckTransaction", conn );
			com.Parameters.Add(new SqlParameter("@nUserID",		SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@nDocumentID",	SqlDbType.Int)).Value = nDocumentID;
			com.CommandType = CommandType.StoredProcedure;
			SqlDataReader reader = com.ExecuteReader();
			
			if ( reader.Read() )
			{
				//transaction exists
				//check if it is disabled
				int nDisabledBy = Convert.ToInt32( reader["DisabledBy"] );
				
				if ( nDisabledBy == 0 )
				{
					//User has downloaded the file and nobody has disabled the transaction.
					//This means that the user is not allowed to download it again!
					return true;
				}
				else
				{
					//User has downloaded the file and somebody has disabled the transaction.
					//This means that the user is allowed to download it again!
					//NOTE - nDisabledBy is UserID of the user who disabled this transaction log!
					return false;
				}
			}
			else
			{
				//transaction doesn't exist
				return false;
			}
		}
		catch ( Exception ex )
		{
			//there was an error - interpret that like the trans doesn't exist!
			sError = ex.Message;
			return false;
		}
		finally 
		{
			conn.Close();
		}
		
	}

	/// <summary>
	/// Returns a user's WinID and DiskID
	/// </summary>
	/// <param name="nUserID">User ID</param>
	/// <param name="sDiskID">Disk ID</param>
	/// <param name="sWinID">Windows ID</param>
	/// <param name="sError">Diagnostic text</param>
	/// <returns>true if OK, false otherwise</returns>
	private bool GetIDs( int nUserID, out string sDiskID, out string sWinID, out string sError )
	{
		sDiskID = "";
		sWinID  = "";
		sError  = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		
		try 
		{
			com = new SqlCommand( "spGetIDs", conn );
			com.Parameters.Add(new SqlParameter("@nUserID",	SqlDbType.Int)).Value = nUserID;
			com.CommandType = CommandType.StoredProcedure;
			SqlDataReader reader = com.ExecuteReader();
			
			if ( reader.Read() )
			{
				sDiskID = reader["DiskID"].ToString();
				sWinID  = reader["WinID"].ToString();
			}
			
			return true;
		}
		catch ( Exception ex )
		{
			sError = "+>"+ex.Message;
			return false;
		}
		finally 
		{
			conn.Close();
		}
		
	}
	
	/// <summary>
	/// Retrieves a list of all documents that a user can download from the server.
	/// </summary>
	/// <param name="nUserID">User ID</param>
	/// <param name="sError">Diagnostic text</param>
	/// <returns>DataSet with list of all documents</returns>
	[WebMethod]
	public DataSet GetDocumentList( int nUserID, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		
		try 
		{
			com = new SqlCommand( "spGetDocumentList", conn );
			com.Parameters.Add(new SqlParameter("@nUserID",	SqlDbType.Int)).Value = nUserID;
			com.CommandType = CommandType.StoredProcedure;

			SqlDataAdapter da = new SqlDataAdapter();
			da.SelectCommand = com;
			
			DataSet ds = new DataSet("DocumentList");
			da.Fill( ds, "Documents" );
			
			return ds;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally 
		{
			conn.Close();
		}
	}
	
	/// <summary>
	/// Retrieves a list of all document that a user can download from the server.
	/// The method is almost identical to GetDocumentList except this one accepts
	/// two more params (document title from and to)
	/// </summary>
	/// <param name="nUserID">User ID</param>
	/// <param name="sError">Diagnostic text</param>
	/// <returns>DataSet with list of all documents</returns>
	[WebMethod]
	public DataSet GetDocumentListEx( int nUserID, string sFrom, string sTo, out string sError )
	{
		sError = "";
		return GetDocumentListEx( nUserID, sFrom, sTo, false, out sError );
	}
	
	[WebMethod]
	public DataSet GetEmptyDocumentList( int nUserID, string sFrom, string sTo, out string sError )
	{
		sError = "";
		return GetDocumentListEx( nUserID, sFrom, sTo, true, out sError );
	}

	private DataSet GetDocumentListEx( int nUserID, string sFrom, string sTo, bool bEmptyDocs, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		
		try 
		{
			if ( bEmptyDocs )
			{
				com = new SqlCommand( "spGetEmptyDocumentList", conn );
				//AddActivity( 0, 0, ACTIVITY_LOGIN, "Called spGetEmptyDocumentList", out sError );
			}
			else
			{
				com = new SqlCommand( "spGetDocumentListEx", conn );
				//AddActivity( 0, 0, ACTIVITY_LOGIN, "Called spGetDocumentListEx", out sError );
			}	
			com.Parameters.Add(new SqlParameter("@nUserID",		SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@sTitleFrom",	SqlDbType.VarChar)).Value = sFrom;
			com.Parameters.Add(new SqlParameter("@sTitleTo",	SqlDbType.VarChar)).Value = sTo;
			com.CommandType = CommandType.StoredProcedure;

			SqlDataAdapter da = new SqlDataAdapter();
			da.SelectCommand = com;
			
			DataSet ds = new DataSet("DocumentList");
			da.Fill( ds, "Documents" );
			
			return ds;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally 
		{
			conn.Close();
		}
	}
	/// <summary>
	/// Returns dataset with all users (Except password and important IDs)
	/// </summary>
	/// <returns>DataSet with all users</returns>
	[WebMethod]
	public DataSet GetAllUsers( out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		
		try 
		{
			com = new SqlCommand( "spGetAllUsers", conn );
			com.CommandType = CommandType.StoredProcedure;

			SqlDataAdapter da = new SqlDataAdapter();
			da.SelectCommand = com;
			
			DataSet ds = new DataSet("UsersDS");
			da.Fill( ds, "Users" );
			
			return ds;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally 
		{
			conn.Close();
		}
	}

	/// <summary>
	/// Retrieves all publishers (all users with at least one published document)
	/// harry:	18.10.2011
	/// </summary>
	/// <param name="sError">Diagnostics</param>
	/// <returns>Data set with publishers</returns>
	[WebMethod]
	public DataSet GetAllPublishers(out string sError)
	{
		sError = "";
		SqlConnection conn = null;

		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return null;
		}

		SqlCommand com = null;

		try
		{
			com = new SqlCommand("spPublishers", conn);
			com.CommandType = CommandType.StoredProcedure;

			SqlDataAdapter da = new SqlDataAdapter();
			da.SelectCommand = com;

			DataSet ds = new DataSet("PublishersDS");
			da.Fill( ds );

			return ds;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return null;
		}
		finally
		{
			conn.Close();
		}
	}

	private DocUser MyLogin( string sUsername, string sPassword, int nClientVer, out string sError ) 
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		if ( sUsername.Length == 0 )
		{
			sError = "Username can't be empty string!";
			return null;
		}
		
		SqlCommand com = null;
		
		try
		{
			com = new SqlCommand( "spGetUser", conn );
			com.Parameters.Add(new SqlParameter("@sUserName",	SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sPassword",	SqlDbType.VarChar)).Value = sPassword;
			com.Parameters.Add(new SqlParameter("@nClientVer",	SqlDbType.Int)).Value = nClientVer;

			SqlParameter parResult = com.Parameters.Add( "@nResult",	SqlDbType.Int );
			parResult.Direction	= ParameterDirection.Output;
			parResult.Value = -1;

			com.CommandType = CommandType.StoredProcedure;
			SqlDataReader reader = com.ExecuteReader();//GMSData.ExecuteSprocQueryReader(com);
			
			if ( reader.Read() )
			{
				int nResult = Convert.ToInt32( parResult.Value );
				//AddActivity( 0, 0, ACTIVITY_LOGIN, string.Format(">>>>>>: {0} {1}", nResult, nClientVer ), out sError );
				
				if ( nResult == -3 )
				{
					AddActivity( 0, 0, ACTIVITY_LOGIN, string.Format("Wrong login by User: {0}",sUsername), out sError );
					sError = "Wrong username and/or password!";
					return null;
				}
				else if ( nResult == -2 )
				{
					AddActivity( 0, 0, ACTIVITY_LOGIN, string.Format("Prohibited client! User:{0} Ver:{1}", sUsername, nClientVer), out sError );
					sError = "You are using obsolete reader, please update from:\r\nhttp://www.drumlinsecurity.co.uk";
				}
				
				DocUser user = new DocUser();
#if _ENTERPRISE_
				Encryption.E1 enc = new Encryption.E1();
#else
				Encryption.MyEncryption enc = new Encryption.MyEncryption();
#endif
				user.m_nID			= Convert.ToInt32( reader[ "ID" ] );
				user.m_nClientID	= Convert.ToInt32( reader[ "ClientID" ] );
				user.m_sEmail1		= reader[ "Email1" ].ToString();
				user.m_sEmail2		= reader[ "Email2" ].ToString();
				user.m_sWeb			= reader[ "Web" ].ToString();
				user.m_sFirstName	= reader[ "FirstName"].ToString();
				user.m_sFamilyName	= reader[ "FamilyName"].ToString();
				user.m_sAddress1	= reader[ "Address1" ].ToString();
				user.m_sAddress2	= reader[ "Address2" ].ToString();
				user.m_sAddress3	= reader[ "Address3" ].ToString();
				user.m_sPostcode	= reader[ "Postcode" ].ToString();
				user.m_sTown		= reader[ "Town" ].ToString();
				user.m_sRegion		= reader[ "Region" ].ToString();
				user.m_sCountry		= reader[ "Country" ].ToString();
				user.m_bGender		= Convert.ToBoolean( reader[ "Gender" ] );
				user.m_sWeb			= reader[ "Web"].ToString();
				user.m_sTel			= reader[ "Telephone"].ToString();
				user.m_sFax			= reader[ "Fax"].ToString();
				user.m_sMob			= reader[ "Mobile"].ToString();
				user.m_nUserType	= Convert.ToInt32( reader[ "UserType" ] );
#if _ENTERPRISE_
				user.m_WinID		= enc.Ex3( reader[ "WinID"].ToString(), out sError );
				user.m_DiskID		= enc.Ex3( reader[ "DiskID"].ToString(), out sError );
				user.m_username		= enc.Ex3( sUsername, out sError );
				user.m_password		= enc.Ex3( sPassword, out sError );
#else
				user.m_WinID		= enc.EncryptString( reader[ "WinID"].ToString(), out sError );
				user.m_DiskID		= enc.EncryptString( reader[ "DiskID"].ToString(), out sError );
				user.m_username		= enc.EncryptString( sUsername, out sError );
				user.m_password		= enc.EncryptString( sPassword, out sError );
#endif
				user.m_sRegCode		= reader[ "RegCode" ].ToString();
				user.m_dtExpires	= Convert.ToDateTime( reader[ "Expires" ] );
				user.m_sOrganisation= reader[ "Organisation" ].ToString();
				user.m_nResult		= nResult;//if -2 this is a prohibited version of the reader				
				//user.m_sWinID		= reader[ "WinID"].ToString();
				//user.m_sDiskID		= reader[ "DiskID"].ToString();
				
				return user;
			}
			else
			{
				AddActivity( 0, 0, ACTIVITY_LOGIN, string.Format("Wrong Login by user: {0}",sUsername), out sError );
				sError = "Wrong username and/or password!";
				return null;
			}
		}
		catch ( Exception ex ) 
		{
			AddActivity( 0, 0, ACTIVITY_LOGIN, string.Format("Wrong login by user: {0} [{1}]",sUsername, ex.Message), out sError );
			sError = ex.Message;
			return null;
		}
		finally
		{
			conn.Close();
		}
	}
		
	[WebMethod]
	public DataSet GetUserIDs( out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		
		try 
		{
			DataSet ds = new DataSet( "UsersDS" );
			DataTable dt = new DataTable( "Users" );
			dt.Columns.Add( new DataColumn( "ID", Type.GetType("System.Int32") ) );
			dt.Columns.Add( new DataColumn( "username", Type.GetType("System.String") ) );
			ds.Tables.Add( dt );
			
			com = new SqlCommand( "spGetUserIDs", conn );
			com.CommandType = CommandType.StoredProcedure;
			SqlDataReader reader = com.ExecuteReader();
			
			while( reader.Read() )
			{
				//al.Add( reader[ "Username" ].ToString() + "(" + reader[ "ID" ].ToString() + ")" );
				DataRow dr = dt.NewRow();
				dr[ "ID" ] = reader[ "ID" ];
				dr[ "Username" ] = reader[ "Username" ];
				
				dt.Rows.Add( dr );
			}
			dt.AcceptChanges();
			ds.AcceptChanges();
			
			return ds;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally 
		{
			conn.Close();
		}
	}

	[WebMethod]
	public int GetUserID( byte[] username, byte[] password, out string sError )
	{
		sError = "";
		try
		{
			string sUsername, sPassword;

#if _ENTERPRISE_
			Encryption.E1 enc = new Encryption.E1();
			sUsername = enc.Dx3(username, out sError);
#else
			Encryption.MyEncryption enc = new Encryption.MyEncryption();
			sUsername = enc.DecryptString(username, out sError);
#endif
			if (sUsername == null) return -80;

#if _ENTERPRISE_
			sPassword = enc.Dx3(password, out sError);
#else
			sPassword = enc.DecryptString(password, out sError);
#endif
			if (sPassword == null) return -90;
			
			return this.GetUserID_plain( sUsername, sPassword, out sError );
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return -100;
		}
	}
	
	private int GetUserID_plain(string sUsername, string sPassword, out string sError)
	{
		sError = "";
		SqlConnection conn = null;

		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
#if DEBUG
			if ( conn == null )
				sError += "NULL ";
			else
				sError += "-->";
			sError += ex.Message;
#else
			sError = ex.Message;
#endif
			return -10;
		}

		SqlCommand com = null;

		try
		{
			com = new SqlCommand("spGetUserID", conn);
			com.Parameters.Add(new SqlParameter("@sUserName", SqlDbType.VarChar)).Value = sUsername;
			com.Parameters.Add(new SqlParameter("@sPassword", SqlDbType.VarChar)).Value = sPassword;

			SqlParameter parResult = com.Parameters.Add("@nResult", SqlDbType.Int);
			parResult.Direction = ParameterDirection.Output;
			parResult.Value = -1;

			com.CommandType = CommandType.StoredProcedure;
			SqlDataReader reader = com.ExecuteReader();//GMSData.ExecuteSprocQueryReader(com);

			if (reader.Read())
			{
				int nResult = Convert.ToInt32(parResult.Value);

				if (nResult == -1)
				{
					sError = "Wrong username and/or password!";
				}
				else
				{
					nResult = Convert.ToInt32( reader[0] );
				}

				return nResult;
			}
			else
			{
				sError = "Wrong username and/or password!";
				return -1;
			}
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return -2;
		}
		finally
		{
			conn.Close();
		}
	}

	private UInt32 Hash(string s)
	{
		UInt32 hash = 1315423911;
		int i = 0;
		UInt32 len = (UInt32)s.Length;

		for (i = 0; i < len; i++)
		{
			hash ^= ((hash << 5) + (s[i]) + (hash >> 2));
		}

		return hash;
	}

	string Scramble(string s)
	{
		System.Text.StringBuilder sb = new System.Text.StringBuilder(s);
		char cTemp;

		int i = 0;
		int nLen = s.Length;

		while (i != nLen)
		{
			if (i + 1 != nLen)
			{
				cTemp = sb[i];
				sb[i] = sb[i + 1];
				sb[i + 1] = cTemp;

				sb[i + 1] ^= (char)31;
				sb[i] ^= (char)31;
				i += 2;
			}
			else
			{
				sb[i] ^= (char)31;
				i++;
			}
		}

		return sb.ToString();
	}
	
	[WebMethod]
	public UInt32 Auth_M(string s1, UInt32 dw1, UInt32 dw2, string sCode, out string sError)
	{
		//s1 - WinID
		//dw1 - disk serial
		//dw2 - doc ID
		//sCode - auth code
		sError = "";
		string s = string.Format("@{0}]{1:x}#{2:x}!{3}_", s1, dw1, dw2, sCode );
		string ss = Scramble(s);
		UInt32 nHash = Hash(ss);

		//public byte[] AuthoriseDocumentNew( int nDocID, int nUserID, string sAuthCode, out string sError )
		byte[] bRes = AuthoriseDocumentNew( (int)dw2, -1, sCode, out sError );
		
		if ( bRes == null ) return 0;
		
		return nHash;
	}

	/// <summary>
	/// Authorises a DRMX file from CaG
	/// 
	/// </summary>
	/// <param name="s1"></param>
	/// <param name="dw1"></param>
	/// <param name="dw2"></param>
	/// <param name="sCode"></param>
	/// <param name="sError"></param>
	/// <returns></returns>
	[WebMethod]
	public byte[] Auth_N(string s1, UInt32 dw1, UInt32 dw2, string sCode, out UInt32 nHash, out string sError)
	{
		//s1 - WinID
		//dw1 - disk serial
		//dw2 - doc ID
		//sCode - auth code
		sError = "";
		nHash = 0;
		string s = string.Format("@{0}]{1:x}#{2:x}!{3}_", s1, dw1, dw2, sCode);
		string ss = Scramble(s);
		nHash = Hash(ss);

		byte[] bRes = AuthoriseDocumentNew((int)dw2, -1, sCode, out sError);

		return bRes;
	}


	[WebMethod]
	public byte[] Auth_O(string s1, UInt32 dw1, UInt32 dw2, string sCode, string sVersion, out UInt32 nHash, out string sError)
	{
		//s1 - WinID
		//dw1 - disk serial
		//dw2 - doc ID
		//sCode - auth code
		//sVersion - added on 2011-09-15
		sError = "";
		nHash = 0;
		string s = string.Format("@{0}]{1:x}#{2:x}!{3}_", s1, dw1, dw2, sCode);
		string ss = Scramble(s);
		nHash = Hash(ss);

		byte[] bRes = AuthoriseDocumentNew_1((int)dw2, -1, sCode, sVersion, out sError);

		return bRes;
	}
	/// <summary>
	/// 
	/// TEst method
	/// 
	/// </summary>
	/// <param name="s1">Windows ID</param>
	/// <param name="dw1">Disk ID</param>
	/// <param name="dw2">Document ID</param>
	/// <param name="sCode">Authorisation code</param>
	/// <param name="sError">Diagnostics</param>
	/// <returns>Hash code if OK, 0,1,2,3 otherwise</returns>
	[WebMethod]
	public UInt32 Test( string s1, UInt32 dw1, UInt32 dw2, string sCode, out string sError )
	{
		sError = "OK";
		
		string s = string.Format( "{0} {1:x}", s1, dw1 );
		string ss = Scramble( s );
		UInt32 nHash = Hash( ss );
		return nHash;
		
/*		sError = "";
		SqlConnection conn = null;

		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -1;
		}
		
		SqlCommand com = null;
		try
		{
			com = new SqlCommand( "spSetUser1", conn );
			com.CommandType = CommandType.StoredProcedure;
			
			int nRes = com.ExecuteNonQuery();
			
			return Convert.ToInt32( nRes );
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return -1;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}*/
	}

	/// <summary>
	/// Sends an email message to admin
	/// </summary>
	/// <param name="sText">Message text</param>
	/// <param name="sError">Diagnostics</param>
	/// <returns>true if OK</returns>
	[WebMethod]
	public bool SendEmail( string sText, string sSubject, out string sError )
	{
		sError = "";
		
		try
		{
			sError = "";
			string sUsername = GetConfigurationEntry( "MailUsername", out sError );
			string sPassword = GetConfigurationEntry( "MailPassword", out sError );
			string sMailServer = GetConfigurationEntry( "MailServer", out sError );
			
			if ( sMailServer.Length == 0 || sUsername.Length == 0 || sPassword.Length == 0 )
			{
				//can't send mails - check web.config
				AddActivity( 0, 0, ACTIVITY_MAIL_ERROR, "Mail server not defined!", out sError );
				return false;
			}

			SmtpClient mail = new SmtpClient( sMailServer );
			mail.Credentials = new System.Net.NetworkCredential( sUsername, sPassword );
			
			MailMessage message = new MailMessage( "no-reply@drumlinsecurity.co.uk", "registration@drumlinsecurity.co.uk", sSubject, sText );
			
			mail.Send( message );
			
			return true;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
		}
	}
	
	[WebMethod]
	public bool SendEmailEx( string sFrom, string sTo, string sText, string sSubject, out string sError )
	{
		sError = "";
		
		try
		{
			sError = "";
			string sUsername = GetConfigurationEntry( "MailUsername", out sError );
			string sPassword = GetConfigurationEntry( "MailPassword", out sError );
			string sMailServer = GetConfigurationEntry( "MailServer", out sError );
			
			if ( sMailServer.Length == 0 || sUsername.Length == 0 || sPassword.Length == 0 )
			{
				//can't send mails - check web.config
				AddActivity( 0, 0, ACTIVITY_MAIL_ERROR, "Mail server not defined (SendMailEx)!", out sError );
				return false;
			}

			SmtpClient mail = new SmtpClient( sMailServer );
			mail.Credentials = new System.Net.NetworkCredential( sUsername, sPassword );
			
			MailMessage message = new MailMessage( sFrom, sTo, sSubject, sText );
			
			mail.Send( message );
			
			return true;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
		}
	}
	
	/// <summary>
	/// Method returns dataset of all users who have already downloaded documents
	/// from "DocIDs". Used after the permissions have been changed to ask admin
	/// whether he would like to disable this user's tramsaction history and thus
	/// enable the users to re-download the document(s).
	/// 
	/// </summary>
	/// <param name="sUserIDs">List of user IDs (string separated by comma)</param>
	/// <param name="sDocIDs">List of document IDs (string separated by comma)</param>
	/// <param name="sError">Diag text</param>
	/// <returns>DataSet with the list</returns>
	[WebMethod]
	public DataSet GetListOfAlreadyDownloadedDocs( string sUserIDs, string sDocIDs, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		
		try 
		{
			com = new SqlCommand( "spUserDLList", conn );
			com.CommandType = CommandType.StoredProcedure;
			
			com.Parameters.Add(new SqlParameter("@sUserIDs", SqlDbType.VarChar)).Value = sUserIDs;
			com.Parameters.Add(new SqlParameter("@sDocIDs", SqlDbType.VarChar)).Value  = sDocIDs;
			
			SqlDataAdapter da = new SqlDataAdapter();
			da.SelectCommand = com;
			
			DataSet ds = new DataSet("UserDocumentList");
			da.Fill( ds );
			
			return ds;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally 
		{
			conn.Close();
		}
	}

    [WebMethod]
    public string Harry()
    {
		try { 
			//return this.Server.MapPath(".");
			//string s = HttpContext.Current.Request.ServerVariables["REMOTE_ADDR"].ToString();
			//return s;
			return "KOKOKOKO";
		}
        catch ( Exception ex ) { return ex.Message; }
    }

	/// <summary>
	/// Method returns SQL connection string
	/// </summary>
	/// <returns></returns>
	private string GetConnectionString( out string sError )
	{
		sError = "";
		return GetConfigurationEntry( "ConnectionString", out sError );
	}
	
	/// <summary>
	/// Returns configuration setting value
	/// </summary>
	/// <param name="sName">Name of the entry</param>
	/// <param name="sError">Diag message</param>
	/// <returns>Entry value</returns>
	private string GetConfigurationEntry( string sName, out string sError )
	{
		sError = "";
		
		try
		{
			string[] sConn = System.Configuration.ConfigurationSettings.AppSettings.GetValues( sName );
			string sTemp = sConn[0];
			
			return sTemp;
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return "";
		}
	}

	/// <summary>
	/// Enables RE-download of some documents to users by setting "DisabledBy"
	/// field in TransHistory table to nUserID.
	/// </summary>
	/// <param name="nUserID">Admin's ID</param>
	/// <param name="sTransHistoryIDs">list of transaction history records</param>
	/// <param name="sError">Diag text</param>
	/// <returns>true if OK</returns>
	[WebMethod]
	public bool EnableDownload( int nUserID, string sTransHistoryIDs, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		try
		{
			com = new SqlCommand( "spEnableDownload", conn );
			com.Parameters.Add(new SqlParameter("@sTransHistoryIDs", SqlDbType.VarChar)).Value = sTransHistoryIDs;
			com.Parameters.Add(new SqlParameter("@nUserID",	SqlDbType.Int)).Value = nUserID;

			com.CommandType = CommandType.StoredProcedure;
			
			com.ExecuteNonQuery();
			
			return true;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}
	
	[WebMethod]
	public byte[] CreateAuthCodesForDocuments( int nUserID, int[] DocIDs, int[] CreatorIDs, int nCodeNum, out string sError )
	{
		sError = "";
		return CreateAuthCodesForDocumentsEx( nUserID, DocIDs, CreatorIDs, nCodeNum, 1, true, out sError );
	}
	
	[WebMethod]
	public byte[] CreateAuthCodesForDocumentsEx( int nUserID, int[] DocIDs, int[] CreatorIDs, int nCodeNum, int nCounter, bool bCheckQuota, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		if ( DocIDs.Length != CreatorIDs.Length )
		{
			sError = "Wrong input parameters!";
			return null;
		}
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		SqlCommand com1= null;
//		string sResult = "";
		string sTemp = "";
		
		try
		{
			Random rand = new Random(unchecked((int)DateTime.Now.Ticks));

			if ( bCheckQuota )
			{
				//check if this user is allowed to create authcode
				com1 = new SqlCommand( "spCheckTestQuota", conn );
				SqlParameter pUID    = new SqlParameter("@nUserID",	SqlDbType.Int);
				SqlParameter pRes    = new SqlParameter("@nResult",	SqlDbType.Int);
				pRes.Direction = ParameterDirection.Output;
				
				com1.Parameters.Add( pUID );
				com1.Parameters.Add( pRes );
				com1.CommandType = CommandType.StoredProcedure;

				pUID.Value = nUserID;
				pRes.Value = 0;
				
				com1.ExecuteNonQuery();
				
				int nRes = Convert.ToInt32( pRes.Value );
				
				if ( nRes < 0 )
				{
					sError = "Free test code quota exceeded. To obtain further test authorization codes please email Drumlin: sales@drumlinsecurity.co.uk";
					return null;
				}

			}

			com = new SqlCommand( "spCreateAuthCode", conn );
			SqlParameter pUserID    = new SqlParameter("@nUserID",	SqlDbType.Int);
			SqlParameter pDocID     = new SqlParameter("@nDocID",	SqlDbType.Int);
			SqlParameter pCreatorID = new SqlParameter("@nCreatorID",	SqlDbType.Int);
			SqlParameter pCode      = new SqlParameter("@sCode",	SqlDbType.VarChar);
			SqlParameter pCounter	= new SqlParameter("@nCounter",	SqlDbType.Int);
			SqlParameter pResult    = new SqlParameter("@nResult",	SqlDbType.Int);

			pResult.Direction = ParameterDirection.Output;

			com.Parameters.Add( pUserID );
			com.Parameters.Add( pDocID );
			com.Parameters.Add( pCreatorID );
			com.Parameters.Add( pCode );
			com.Parameters.Add( pCounter );
			com.Parameters.Add( pResult );
			
			com.CommandType = CommandType.StoredProcedure;
			
			object[] array = new object[ 2 * DocIDs.Length * nCodeNum ];
			int nResult = 0;
			int nIndex = 0;
			
			for ( int i=0; i<DocIDs.Length; i++ )
			{
				for( int j=0; j<nCodeNum; j++ )
				{
					sTemp = GenerateAuthCode( rand, 20 );
					
					pUserID.Value    = nUserID;
					pDocID.Value     = DocIDs[ i ];
					pCreatorID.Value = CreatorIDs[ i ];
					pCode.Value      = sTemp;
					pCounter.Value	 = nCounter;
					pResult.Value	 = 0;
					
					com.ExecuteNonQuery();
					
					nResult = Convert.ToInt32( pResult.Value );
					
					if ( nResult > 0 )
					{
						//code created OK
						array[ nIndex ++ ] = DocIDs[ i ];
						array[ nIndex ++ ] = sTemp;
					}
					else
					{
						//error
						array[ nIndex ++ ] = DocIDs[ i ];
						array[ nIndex ++ ] = "";
						//this is probably because user type is not 0!
						//discuss this with Mike
						sError = "You're not allowed to create authorization codes!";
						return null;
					}
//					sTemp += string.Format( "  ID=[{0}]\r\n", pResult.Value );
//					sResult += (DocIDs[i].ToString() + "=" + sTemp);
				}
			}
					
			return EncodeArray( array, nUserID, out sError );
		}
		catch ( Exception ex )
		{
			sError = "--->"+ex.Message;
			return null;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}
	
	private static string m_sBuffer = "23456789ABCDEFGHJKMNPQRSTUVWXZYabcdefghjkmnpqrstuvwxzy";
	private static string GenerateAuthCode( Random rand, int nCodeLen )
	{
		char[] data = new char[nCodeLen];

		for ( int i=0; i<nCodeLen; i++ )
		{
			data[i] = m_sBuffer[ rand.Next( 0, m_sBuffer.Length-1 ) ];
		}

		return new string( data );
	}
	
	/// <summary>
	/// Uses authentication code for authorisation of a document.
	/// 
	/// 13.04.2007
	/// </summary>
	/// <param name="nDocID">Document to be authorised</param>
	/// <param name="nUserID">User who does it</param>
	/// <param name="sAuthCode">The authentication code</param>
	/// <param name="sError">Diag text</param>
	/// <returns>true if successfull</returns>
	[WebMethod]
	public bool AuthoriseDocumentEx( int nDocID, int nUserID, string sAuthCode, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		try
		{
			com = new SqlCommand( "spAuthoriseDocument", conn );
			com.Parameters.Add(new SqlParameter("@nDocID",	SqlDbType.Int)).Value = nDocID;
			com.Parameters.Add(new SqlParameter("@nUserID",	SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@sCode",	SqlDbType.VarChar)).Value = sAuthCode;
			
			SqlParameter param = com.Parameters.Add( "@nResult", SqlDbType.Int );
			param.Direction = ParameterDirection.Output;

			com.CommandType = CommandType.StoredProcedure;
			
			com.ExecuteNonQuery();
			
			int nRes = (int)param.Value;
			string sError1 = "";
			
			if ( nRes == -1 )
			{
				sError = "Wrong Authorization Code!";
				
				//Add activity
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4})",
					nUserID, nDocID, sAuthCode, sError, nRes );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return false;
			}
			else if ( nRes == -2 )
			{
				sError = "Authorization Code Not Valid For This Document!";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4})",
					nUserID, nDocID, sAuthCode, sError, nRes );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return false;
			}
			else if ( nRes == -3 )
			{
				sError = "Authorization Code Already Used!";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4})",
					nUserID, nDocID, sAuthCode, sError, nRes );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return false;
			}
			else if ( nRes == 0 )
			{
				string sDesc = string.Format( "Authorization successful - UserID:{0} DocID:{1}",
					nUserID, nDocID );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_OK, sDesc, out sError1 );
				return true;
			}
			else
			{
				sError = "Unknown error ("+nRes.ToString()+")!";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4})",
					nUserID, nDocID, sAuthCode, sError, nRes );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return false;
			}
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}

	[WebMethod]
	public byte[] CanConvertDocEx( byte[] Username, byte[] Password, int nDocID, int nClientVer, int nAuthType, out string sError )
	{
		sError = "";

		DocUser du = GetUserData(Username, Password, nClientVer, out sError);
		if (du == null) return null;

		if ((du.m_nUserType == (int)UserTypes.ADMINS) || ((du.m_nUserType & (int)UserTypes.CAN_CREATE_EXE) == (int)UserTypes.CAN_CREATE_EXE))
		{
			return GetDocHCKS_1(nDocID, du.m_nClientID, nAuthType, out sError);
		}
		else
		{
			//sError = "ERROR: Unable to Convert Document!";
			sError = "ERROR: Cannot convert file to EXE format!\r\n\r\nplease upgrade to Drumlin V6/Javelin for this functionality";
			string s = "";
			AddActivity(du.m_nClientID, nDocID, ACTIVITY_AUTH_ERROR, "ERROR: Unable to create EXE! DocID:"+nDocID.ToString(), out s);
			return null;
		}
	}
	
	[WebMethod]
	public byte[] CanConvertDoc( byte[] Username, byte[] Password, int nDocID, int nClientVer, out string sError )
	{
		sError = "";
		
		return CanConvertDocEx( Username, Password, nDocID, nClientVer, -1, out sError );
	}

	[WebMethod]
	public byte[] CanConvertDocPDK(byte[] Username, byte[] Password, int nDocID, int nClientVer, out string sError)
	{
		sError = "";

		return CanConvertDocPDKEx( Username, Password, nDocID, nClientVer, -1, out sError );
	}

	[WebMethod]
	public byte[] CanConvertDocPDKEx(byte[] Username, byte[] Password, int nDocID, int nClientVer, int nAuthType, out string sError)
	{
		sError = "";

		DocUser du = GetUserDataPDK(Username, Password, nClientVer, out sError);
		if (du == null) return null;

		if ((du.m_nUserType == (int)UserTypes.ADMINS) || ((du.m_nUserType & (int)UserTypes.CAN_CREATE_EXE) == (int)UserTypes.CAN_CREATE_EXE))
		{
			//04/07/2011 - unable v5 and v6.000 to generate exe
			/*			if ( nClientVer > 5000 && nClientVer <= 6000 )
						{
							sError = "ERROR: Your client is temporarily prevented from generating Drumlin EXE files!";
							string s = "";
							AddActivity(du.m_nClientID, nDocID, ACTIVITY_AUTH_ERROR, sError, out s);
							return null;
						}*/
			return GetDocHCKS_1(nDocID, du.m_nClientID, nAuthType, out sError);
		}
		else
		{
			sError = "ERROR: Cannot convert file to EXE format!\r\n\r\nplease upgrade to Drumlin V6/Javelin for this functionality";
			string s = "";
			AddActivity(du.m_nClientID, nDocID, ACTIVITY_AUTH_ERROR, "ERROR: Unable to create EXE! DocID:" + nDocID.ToString(), out s);
			return null;
		}
	}

	private byte[] GetDocHCKS_1(int nDocID, int nUserID, int nAuthType, out string sError)
	{
		SqlConnection conn = null;

		if (nUserID == 0)
		{
			string sDesc = string.Format("Authorization error - Unregistered client! DocID:{0}", nDocID);
			AddActivity(nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError);

			sError = "ERROR: Your client is not registered properly!\r\nCan't authorize the document: " + nDocID.ToString();
			return null;
		}

		try
		{
			conn = GetConnection(out sError);
			conn.Open();
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return null;
		}

		SqlCommand com = null;
		try
		{
			com = new SqlCommand("spGetHCKS", conn);
			com.Parameters.Add(new SqlParameter("@nDocID", SqlDbType.Int)).Value = nDocID;
			com.Parameters.Add(new SqlParameter("@nUserID", SqlDbType.Int)).Value = nUserID;

			byte[] binRes = new byte[16];

			SqlParameter param1 = com.Parameters.Add("@binHCKS", SqlDbType.Binary, 16);
			param1.Direction = ParameterDirection.Output;
			param1.Value = binRes;

			SqlParameter param = com.Parameters.Add("@nResult", SqlDbType.Int);
			param.Direction = ParameterDirection.Output;

			com.CommandType = CommandType.StoredProcedure;

			com.ExecuteNonQuery();

			int nRes = (int)param.Value;
			string sError1 = "";

			if (nRes == -5)
			{
				sError = "Your user record in Drumlin database doesn't exist!";
				string sDesc = string.Format("ExeGen - UserID:{0} DocID:{1} ({2} {3}) AT:{4}",
					nUserID, nDocID, sError, nRes, nAuthType);

				AddActivity(nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1);
				return null;
			}
			else if (nRes == -6)
			{
				sError = "Your Drumlin account has expired!";
				string sDesc = string.Format("ExeGen - UserID:{0} DocID:{1} ({2} {3}) AT:{4}",
					nUserID, nDocID, sError, nRes, nAuthType);

				AddActivity(nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1);
				return null;
			}
			else if (nRes == -10)
			{
				sError = "Document doesn't exist!";
				string sDesc = string.Format("ExeGen - UserID:{0} DocID:{1} ({2} {3}) AT:{4}",
					nUserID, nDocID, sError, nRes, nAuthType);

				AddActivity(nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1);
				return null;
			}
			else if (nRes == -111)
			{
				sError = "You'll have to update your Drumlin reader to authorize this document.";
				string sDesc = string.Format("ExeGen - UserID:{0} DocID:{1} ({2} {3}) AT:{4}",
					nUserID, nDocID, sError, nRes, nAuthType);

				AddActivity(nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1);
				return null;
			}
			else if (nRes == 0)
			{
				string sDesc = string.Format("ExeGen successful - UserID:{0} DocID:{1} AT:{2}",
					nUserID, nDocID, nAuthType);

				AddActivity(nUserID, nDocID, ACTIVITY_AUTH_OK, sDesc, out sError1);

				//byte[] binHCKS = (byte[])param1.Value;
				//return binHCKS;

				return (byte[])param1.Value;
			}
			else
			{
				sError = "Unknown error (" + nRes.ToString() + ")!";
				string sDesc = string.Format("ExeGen - UserID:{0} DocID:{1} ({2} {3}) AT:{4}",
					nUserID, nDocID, sError, nRes, nAuthType);

				AddActivity(nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1);
				return null;
			}
		}
		catch (Exception ex)
		{
			sError = ex.Message;
			return null;
		}
		finally
		{
			if (conn != null) conn.Close();
		}
	}
	
	private byte[] GetDocHCKS(int nDocID, int nUserID, out string sError)
	{
		sError = "";
		return GetDocHCKS_1( nDocID, nUserID, -1, out sError );
	}

	[WebMethod]
	public byte[] AuthoriseDocumentNew( int nDocID, int nUserID, string sAuthCode, out string sError )
	{
		sError = "";
		return AuthoriseDocumentNew_1(nDocID, nUserID, sAuthCode, "n/a", out sError );
	}
	/// <summary>
	/// Uses authentication code for authorisation of a document.
	/// Returns HCKS (server part of HCK if successful)
	/// 
	/// 19.10.2007
	/// </summary>
	/// <param name="nDocID">Document to be authorised</param>
	/// <param name="nUserID">User who does it</param>
	/// <param name="sAuthCode">The authentication code</param>
	/// <param name="sVersion">Client version (2011-09-15)</param> 
	/// <param name="sError">Diag text</param>
	/// <returns>true if successfull</returns>
	[WebMethod]
	public byte[] AuthoriseDocumentNew_1( int nDocID, int nUserID, string sAuthCode, string sVersion, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		if ( nUserID == 0 )
		{
			string sDesc = string.Format( "Authorization error - Unregistered client! DocID:{0}", nDocID );
			AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError );

			sError = "ERROR: Your client is not registered properly!\r\nCan't authorize the document: "+nDocID.ToString();
			return null;
		}
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		try
		{
			com = new SqlCommand( "spAuthoriseDocumentNew", conn );
			com.Parameters.Add(new SqlParameter("@nDocID",	SqlDbType.Int)).Value = nDocID;
			com.Parameters.Add(new SqlParameter("@nUserID",	SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@sCode",	SqlDbType.VarChar)).Value = sAuthCode;

			byte[] binRes = new byte[16];
			
			SqlParameter param1 = com.Parameters.Add( "@binHCKS", SqlDbType.Binary, 16 );
			param1.Direction = ParameterDirection.Output;
			param1.Value = binRes;
			
			SqlParameter param = com.Parameters.Add( "@nResult", SqlDbType.Int );
			param.Direction = ParameterDirection.Output;

			com.CommandType = CommandType.StoredProcedure;
			
			com.ExecuteNonQuery();
			
			int nRes = (int)param.Value;
			string sError1 = "";
			
			if ( nRes == -1 )
			{
				sError = "Wrong Authorization Code!";
				
				//Add activity
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4}) {5}",
					nUserID, nDocID, sAuthCode, sError, nRes, sVersion );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return null;
			}
			else if ( nRes == -2 )
			{
				sError = "Authorization Code Not Valid For This Document!";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4}) {5}",
					nUserID, nDocID, sAuthCode, sError, nRes, sVersion );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return null;
			}
			else if ( nRes == -3 )
			{
				sError = "Authorization Code Already Used!";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4}) {5}",
					nUserID, nDocID, sAuthCode, sError, nRes, sVersion );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return null;
			}
			else if ( nRes == -4 )
			{
				sError = "You're not allowed to use this Authorization code!";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4}) {5}",
					nUserID, nDocID, sAuthCode, sError, nRes, sVersion );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return null;
			}
			else if ( nRes == -5 )
			{
				sError = "Your user record in Drumlin database doesn't exist!";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4}) {5}",
					nUserID, nDocID, sAuthCode, sError, nRes, sVersion );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return null;
			}
			else if ( nRes == -6 )
			{
				sError = "Your Drumlin account has expired!";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4}) {5}",
					nUserID, nDocID, sAuthCode, sError, nRes, sVersion );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return null;
			}
			else if ( nRes == -111 )
			{
				sError = "You'll have to update your Drumlin reader to authorize this document.";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4}) {5}",
					nUserID, nDocID, sAuthCode, sError, nRes, sVersion );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return null;
			}
			else if ( nRes == 0 )
			{
				string sDesc = string.Format( "Authorization successful - UserID:{0} DocID:{1} Code:{2} {3}",
					nUserID, nDocID, sAuthCode, sVersion );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_OK, sDesc, out sError1 );
				
				//byte[] binHCKS = (byte[])param1.Value;
				//return binHCKS;
				
				return (byte[])param1.Value;
			}
			else
			{
				sError = "Unknown error ("+nRes.ToString()+")!";
				string sDesc = string.Format( "Authorization - UserID:{0} DocID:{1} Code:{2} ({3} {4}) {5}",
					nUserID, nDocID, sAuthCode, sError, nRes, sVersion );
				
				AddActivity( nUserID, nDocID, ACTIVITY_AUTH_ERROR, sDesc, out sError1 );
				return null;
			}
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
	}

	/// <summary>
	/// Post result of authorisation.
	/// In case of error - the used code will be reset (e.g. incremented by 1)
	/// and will be usable again.
	/// 
	/// </summary>
	/// <param name="nUserID">USER ID</param>
	/// <param name="nDocID">DOC ID</param>
	/// <param name="sText">Activity description</param>
	/// <param name="sCode">Auth code</param>
	/// <param name="sError">Diag text</param>
	[WebMethod]
	public bool PostAuthorOutcome( int nUserID, int nDocID, string sText, string sCode, out string sError )
	//( int nUserID, int nDocID, string sText, string sCode, out string sError )
	{
		sError = "";
		int nActivity = ACTIVITY_POST_AUTH_OK;
		if ( sText.StartsWith( "ERR" ) )
			nActivity = ACTIVITY_AUTH_ERROR;
			
		AddActivity(nUserID, nDocID, nActivity, sText, out sError );
		
		if ( sCode.Length > 0 && nActivity == ACTIVITY_AUTH_ERROR )
		{
			//reset auth code in case of error
			if ( !IncrementAuthCodeCounter( nDocID, sCode, 1, out sError ) )
			{
				string sE = "";
				AddActivity(nUserID, nDocID, nActivity, sError, out sE);
				return false;
			}
		}
		
		return true;
	}

	private bool IncrementAuthCodeCounter( int nDocID, string sCode, int nIncrement, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		
		try 
		{
			com = new SqlCommand( "spResetAuthCode", conn );
			com.Parameters.Add(new SqlParameter("@nDocID",		SqlDbType.Int)).Value = nDocID;
			com.Parameters.Add(new SqlParameter("@nIncrement",	SqlDbType.Int)).Value = nIncrement;
			com.Parameters.Add(new SqlParameter("@sCode",		SqlDbType.VarChar)).Value = sCode;

			SqlParameter param = com.Parameters.Add("@nResult", SqlDbType.Int);
			param.Direction = ParameterDirection.Output;

			com.CommandType = CommandType.StoredProcedure;

			com.ExecuteNonQuery();
			int nRes = (int)param.Value;
			
			if ( nRes != 0 )
			{
				sError = string.Format( "AuthCode doesn't exist!" );
				return false;
			}
			return true;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally 
		{
			conn.Close();
		}
	}

		/// <summary>
	/// Inserts "nCount" blank (un-initialised) users with RegCode prefix "sPrefix"
	/// and returns data set with all newly inserted users.
	/// </summary>
	/// <param name="nCount">Number of users to insert</param>
	/// <param name="sPrefix">Reg code prefix</param>
	/// <param name="sError">Diag text</param>
	/// <returns>DataSet with all created users or NULL in case of error.</returns>
	[WebMethod]
	public DataSet InsertBlankUsers( int nCount, string sPrefix, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;
		
		try 
		{
			com = new SqlCommand( "spInsertBlankUsers", conn );
			com.Parameters.Add(new SqlParameter("@nCount",	SqlDbType.Int)).Value = nCount;
			com.Parameters.Add(new SqlParameter("@sPrefix", SqlDbType.VarChar)).Value = sPrefix;
			com.CommandType = CommandType.StoredProcedure;

			SqlDataAdapter da = new SqlDataAdapter();
			da.SelectCommand = com;
			
			DataSet ds = new DataSet("InsertedUsers");
			da.Fill( ds, "Users" );
			
			return ds;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return null;
		}
		finally 
		{
			conn.Close();
		}
	}
	
	
	/// <summary>
	/// Logs an exception error to the database
	/// </summary>
	/// <param name="nUserID"></param>
	/// <param name="sPage"></param>
	/// <param name="sMessage"></param>
	/// <param name="sSource"></param>
	/// <param name="sMethod"></param>
	/// <param name="sStackTrace"></param>
	/// <param name="sError"></param>
	/// <returns>TRUE if OK</returns>
	[WebMethod]
	public bool LogErrorToDB( int nUserID, string sPage, string sMessage, string sSource, string sMethod, string sStackTrace, out string sError )
	{
		sError = "";
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;
		
		try 
		{
			com = new SqlCommand( "spLogErrorToDB", conn );
			com.Parameters.Add(new SqlParameter("@nUserID",	SqlDbType.Int)).Value = nUserID;
			com.Parameters.Add(new SqlParameter("@sPage", SqlDbType.VarChar)).Value = sPage;
			com.Parameters.Add(new SqlParameter("@sMessage", SqlDbType.VarChar)).Value = sMessage;
			com.Parameters.Add(new SqlParameter("@sSource", SqlDbType.VarChar)).Value = sSource;
			com.Parameters.Add(new SqlParameter("@ssMethod", SqlDbType.VarChar)).Value = sMethod;
			com.Parameters.Add(new SqlParameter("@sStackTrace", SqlDbType.VarChar)).Value = sStackTrace;
			com.CommandType = CommandType.StoredProcedure;

			com.ExecuteNonQuery();
			
			return true;
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally 
		{
			conn.Close();
		}
	}
	
	/// <summary>
	/// Uploads new client to the DB.
	/// </summary>
	/// <param name="nUserID">User ID of user who uploads</param>
	/// <param name="bPass">This user's USK encrypted password</param>
	/// <param name="nMajor">Major version number</param>
	/// <param name="nMinor">Minor version number</param>
	/// <param name="dtDate">Date of build</param>
	/// <param name="data">Code</param>
	/// <param name="sError">Diag text</param>
	/// <returns>TRUE if OK</returns>
	[WebMethod]
	public bool UploadNewClient( int nUserID, byte[] bPass, int nMajor, int nMinor, DateTime dtDate, byte[] data, out string sError )
	{
		sError = "";
		
		if ( !this.CheckPassword( nUserID, bPass, false, out sError ) )
		{
			return false;
		}

		if ( data == null )
		{
			sError = "Invalid data!";
			return false;
		}
		
		if ( data.Length == 0 )
		{
			sError = "Invalid data!";
			return false;
		}

		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;

		try
		{
			com = new SqlCommand( "spLoadNewClientExe", conn );
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add( "@nVersionMajor", SqlDbType.Int ).Value    = nMajor;
			com.Parameters.Add( "@nVersionMinor", SqlDbType.Int ).Value    = nMinor;
			com.Parameters.Add( "@fileData",      SqlDbType.Binary ).Value = data;
			com.Parameters.Add( "@dateVersion",	  SqlDbType.DateTime ).Value = dtDate;
			
			SqlParameter param = com.Parameters.Add( "@returnValue", SqlDbType.Int );
			param.Direction = ParameterDirection.Output;

			com.ExecuteNonQuery();
			int nRes = (int)param.Value;
			
			if ( nRes == 0 )
			{
				sError = "Client EXE uploaded successfully!";
				return true;
			}
			else if ( nRes == 1 )
			{
				sError = "This version of client already exists in the DB!";
			}
			return false;
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			conn.Close();
		}
	}
	
	/// <summary>
	/// Deletes existing client from the DB
	/// </summary>
	/// <param name="nUserID">User who uploads EXE</param>
	/// <param name="bPass">Encrypted password</param>
	/// <param name="nMajor">Major version number</param>
	/// <param name="nMinor">Minor version number</param>
	/// <param name="sError">Diag text</param>
	/// <returns>TRUE if OK</returns>
	[WebMethod]
	public bool DeleteClient( int nUserID, byte[] bPass, int nMajor, int nMinor, out string sError )
	{
		sError = "";
		
		if ( !this.CheckPassword( nUserID, bPass, false, out sError ) )
		{
			return false;
		}

		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;

		try
		{
			com = new SqlCommand( "spDeleteClient", conn );
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add( "@nVerMajor", SqlDbType.Int ).Value    = nMajor;
			com.Parameters.Add( "@nVerMinor", SqlDbType.Int ).Value    = nMinor;
			
			com.ExecuteNonQuery();
			return true;
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			conn.Close();
		}
	}
	
	[WebMethod]
	public byte[] DownloadLatestClient( int nUserID, out string sError ) 
	{
		sError = "";
		return DownloadLatestClientV4( nUserID, 3, out sError );
	}

	[WebMethod]
	public byte[] DownloadLatestClientV4( int nUserID, int nMajorVer, out string sError ) 
	{
		byte[] result = null;
		sError = "";
		
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;

		try 
		{
			if ( nMajorVer < 4 )
				com = new SqlCommand( "spDownloadLatestClient", conn );
			else
				com = new SqlCommand( "spDownloadLatestClientV4", conn );
			
			com.Parameters.Add(new SqlParameter("@nUserID",		SqlDbType.Int)).Value = nUserID;

			com.CommandType = CommandType.StoredProcedure;

			SqlDataReader dr = com.ExecuteReader();
			dr.Read();

			result = (byte[])dr.GetValue( 0 );
			
			dr.Close();
		}
		catch(SqlException ex) 
		{
			sError = ex.Message;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
		 
		return result;
	}

	/// <summary>
	/// Returns the most recent major and minor version numbers of uploaded clients.
	/// </summary>
	/// <param name="nMajor">Major version number</param>
	/// <param name="nMinor">Minor version number</param>
	/// <param name="sError">Diag text</param>
	/// <returns>TRUE if OK</returns>
	[WebMethod]
	public bool GetMaxVersionNo( out int nMajor, out int nMinor, out string sError )
	{
		sError = "";
		nMajor = -1;
		nMinor = -1;
		long lCS = -1;
				
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;

		try
		{
			com = new SqlCommand( "spGetMaxDLVersionNo", conn );
			com.CommandType = CommandType.StoredProcedure;

			SqlParameter parMaj = com.Parameters.Add( "@nVerMaj",	SqlDbType.Int);
			parMaj.Direction	= ParameterDirection.Output;
			
			SqlParameter parMin = com.Parameters.Add( "@nVerMin",	SqlDbType.Int);
			parMin.Direction	= ParameterDirection.Output;

			SqlParameter parCS = com.Parameters.Add( "@nCS",	SqlDbType.Int);
			parCS.Direction	= ParameterDirection.Output;

			com.ExecuteNonQuery();

			nMajor = (int)parMaj.Value;
			nMinor = (int)parMin.Value;
			try{ lCS	   = (long)parCS.Value; }
			catch { lCS = 0; }
			
			return true;
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			conn.Close();
		}
	}

/*	{
		sError = "";
		nMajor = -1;
		nMinor = -1;
				
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;

		try
		{
			com = new SqlCommand( "spGetMaxVersionNo", conn );
			com.CommandType = CommandType.StoredProcedure;

			SqlParameter parMaj = com.Parameters.Add( "@nVerMaj",	SqlDbType.Int);
			parMaj.Direction	= ParameterDirection.Output;
			
			SqlParameter parMin = com.Parameters.Add( "@nVerMin",	SqlDbType.Int);
			parMin.Direction	= ParameterDirection.Output;

			com.ExecuteNonQuery();

			if ( parMaj.Value == DBNull.Value || parMin.Value == DBNull.Value )
			{
				sError = "No new clients!";
				return false;
			}
			
			nMajor = (int)parMaj.Value;
			nMinor = (int)parMin.Value;

			return true;
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			conn.Close();
		}
	}*/
	
	[WebMethod]
	public bool GetMaxVersionNoNew( ref int nMajor, ref int nMinor, out string sError )
	{
		sError = "";
		int nVer = nMajor*1000 + nMinor;
		
		if ( nVer < 2000 )
		{
			sError = "Major update required - please download a new kit and install the latest complete version";
			return false;
		}
		
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;

		try
		{
			if ( nMajor < 4 )
				com = new SqlCommand( "spGetMaxVersionNo", conn );
			else
				com = new SqlCommand( "spGetMaxVersionNoV4", conn );//support for V4 reader

			com.CommandType = CommandType.StoredProcedure;

			SqlParameter parMaj = com.Parameters.Add( "@nVerMaj",	SqlDbType.Int);
			parMaj.Direction	= ParameterDirection.Output;
			
			SqlParameter parMin = com.Parameters.Add( "@nVerMin",	SqlDbType.Int);
			parMin.Direction	= ParameterDirection.Output;

			com.ExecuteNonQuery();

			if ( parMaj.Value == DBNull.Value || parMin.Value == DBNull.Value )
			{
				sError = "No new clients!";
				return false;
			}
			
			nMajor = (int)parMaj.Value;
			nMinor = (int)parMin.Value;

			return true;
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			conn.Close();
		}
	}

	[WebMethod]
	public bool GetDLVersion( out int nMajor, out int nMinor, out long lCS, out string sError )
	{
		sError = "";
		nMajor = -1;
		nMinor = -1;
		lCS = -1;
				
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;

		try
		{
			com = new SqlCommand( "spGetMaxDLVersionNo", conn );
			com.CommandType = CommandType.StoredProcedure;

			SqlParameter parMaj = com.Parameters.Add( "@nVerMaj",	SqlDbType.Int);
			parMaj.Direction	= ParameterDirection.Output;
			
			SqlParameter parMin = com.Parameters.Add( "@nVerMin",	SqlDbType.Int);
			parMin.Direction	= ParameterDirection.Output;

			SqlParameter parCS = com.Parameters.Add( "@nCS",	SqlDbType.Int);
			parCS.Direction	= ParameterDirection.Output;

			com.ExecuteNonQuery();

			nMajor = (int)parMaj.Value;
			nMinor = (int)parMin.Value;
			try{ lCS	   = (long)parCS.Value; }
			catch { lCS = 0; }
			
			return true;
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			conn.Close();
		}
	}

	
	[WebMethod]
	public bool UploadDownloader( int nUserID, byte[] bPass, int nMajor, int nMinor, DateTime dtDate, byte[] data, out string sError )
	{
		sError = "";
		
		if ( !this.CheckPassword( nUserID, bPass, false, out sError ) )
		{
			return false;
		}

		if ( data == null )
		{
			sError = "Invalid data!";
			return false;
		}
		
		if ( data.Length == 0 )
		{
			sError = "Invalid data!";
			return false;
		}
		
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;

		try
		{
			//calculate checksum
			long lCS = 0;
			long lLen = data.Length;

			for( int i=0; i<(int)lLen; i++ ) 
			{
				lCS += data[i];
			}

			com = new SqlCommand( "spLoadDownloader", conn );
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add( "@nVersionMajor", SqlDbType.Int ).Value    = nMajor;
			com.Parameters.Add( "@nVersionMinor", SqlDbType.Int ).Value    = nMinor;
			com.Parameters.Add( "@nCS",			  SqlDbType.BigInt ).Value = lCS;
			com.Parameters.Add( "@fileData",      SqlDbType.Binary ).Value = data;
			com.Parameters.Add( "@dateVersion",	  SqlDbType.DateTime ).Value = dtDate;
			
			SqlParameter param = com.Parameters.Add( "@returnValue", SqlDbType.Int );
			param.Direction = ParameterDirection.Output;

			com.ExecuteNonQuery();
			int nRes = (int)param.Value;
			
			if ( nRes == 0 )
			{
				sError = "Downloader uploaded successfully!";
				return true;
			}
			else if ( nRes == 1 )
			{
				sError = "This version of downloader already exists in the DB!";
			}
			return false;
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			conn.Close();
		}
	}

	[WebMethod]
	public bool DeleteDL( int nUserID, byte[] bPass, int nMajor, int nMinor, out string sError )
	{
		sError = "";
		
		if ( !this.CheckPassword( nUserID, bPass, false, out sError ) )
		{
			return false;
		}

		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return false;
		}
		
		SqlCommand com = null;

		try
		{
			com = new SqlCommand( "spDeleteDL", conn );
			com.CommandType = CommandType.StoredProcedure;
			com.Parameters.Add( "@nVerMajor", SqlDbType.Int ).Value    = nMajor;
			com.Parameters.Add( "@nVerMinor", SqlDbType.Int ).Value    = nMinor;
			
			com.ExecuteNonQuery();
			return true;
		}
		catch( Exception ex )
		{
			sError = ex.Message;
			return false;
		}
		finally
		{
			conn.Close();
		}
	}

	[WebMethod]
	public byte[] DownloadLatestDLer( int nUserID, out string sError ) 
	{
		byte[] result = null;
		sError = "";
		
		SqlConnection conn = null;
		
		try 
		{
			conn = GetConnection( out sError);
			conn.Open();
		}
		catch ( Exception ex ) 
		{
			sError = ex.Message;
			return null;
		}
		
		SqlCommand com = null;

		try 
		{
			com = new SqlCommand( "spDownloadLatestDLer", conn );
			com.Parameters.Add(new SqlParameter("@nUserID",		SqlDbType.Int)).Value = nUserID;

			com.CommandType = CommandType.StoredProcedure;

			SqlDataReader dr = com.ExecuteReader();
			dr.Read();

			result = (byte[])dr.GetValue( 0 );
			
			dr.Close();
		}
		catch(SqlException ex) 
		{
			sError = ex.Message;
		}
		finally
		{
			if ( conn != null ) conn.Close();
		}
		 
		return result;
	}

	/// <summary>
	/// Method authorises a document for one user. Basically it checks if there is already
	/// transaction created for DocID/USerID and if it wasn't creates one and allows
	/// user to re-code the document for future use.
	/// </summary>
	/// <param name="nDocumentID">Document to be authorised</param>
	/// <param name="nUserID">User</param>
	/// <param name="sError">Diag text</param>
	/// <returns>TRUE if OK</returns>
	[WebMethod]
	public bool AuthoriseDocument( int nDocumentID, int nUserID, out string sError )
	{
		sError = "";
		SqlConnection connection = null;
		
		try 
		{
			connection = GetConnection( out sError);
			connection.Open();
		}
		catch ( Exception ex )
		{
			sError = ex.Message+"....";
			return false;
		}
		
		//SqlCommand com = null;

		try
		{
			//int nResult = 0;

			if ( nUserID != 0 )
			{
				if ( CheckTransaction( nUserID, nDocumentID, out sError ) )
				{
					//if the transaction exists - document is already authorised!
					sError = "Document cannot be authorized more then once.\r\nPlease contact someone!";
					return false;
				}
			}

			connection.Close();
			connection = null;

			return AddTransaction( nDocumentID, nUserID, 1, out sError );
		}
		catch (Exception ex)
		{
			sError = "----"+ex.Message;//+"\r\n\r\n"+ex.StackTrace+"\r\n\r\n"+sTemp;
			return false;
		}
		finally
		{
			if (connection != null)
			{
				connection.Close();
				connection = null;
			}
		}
	}
	
	/// <summary>
	/// Returns a valid SQL connection or NULL if fails
	/// </summary>
	/// <returns></returns>
	private SqlConnection GetConnection( out string sError )
	{
		sError = "";
		string sConn = GetConnectionString( out sError );
		if ( sConn.Length == 0 )
		{
			return null;
		}
		
		try
		{
			return new SqlConnection( sConn );
		}
		catch ( Exception ex )
		{
			sError = ex.Message;
#if DEBUG
			sError += "----" + sConn;
#endif
			return null;
		}
	}

	[ XmlInclude(typeof( DocInfo ) ), Serializable ]
	public class DocInfo 
	{
		public DocInfo(){}
		
		public int m_nID					= 0;
		public string m_sName				= "";
		public string m_sDesc				= "";
		public DateTime	m_datePublished		= DateTime.Now;
		public string m_sVersion			= "";
		public DateTime m_dateUploaded		= DateTime.Now;
		public int	m_nDocSize				= 0;
		public string m_sISBN				= "";
		public int m_nOwnerID				= 0;
		public int m_nCreatorID				= 0;
		public int m_nDocState				= 0;
		public string m_sFile				= "";
		public DateTime m_dtExpiry			= DateTime.Now.AddYears( 5 );
		public bool m_bUSK					= true;
		public bool m_bMultiDL				= false;
		public bool m_bKeepVer				= true;
		public bool m_bMustBeOnline			= false;
		public bool m_bMustBeRegistered		= false;
		public bool m_bAllowNetworkPrinting	= true;
		public bool m_bEnableClipboard		= false;
		public bool m_bBlockGrabbers		= true;
		public  byte[] m_HCKS				= new byte[16];
		public string m_sDocPwd				= "";
	}
	
	[ XmlInclude(typeof( DocUser ) ) ]
	public class DocUser 
	{
		public DocUser(){}
	
		public	int		m_nID		= 0;
		public	string	m_sFirstName= "";
		public	string	m_sFamilyName= "";
		//public	string	m_sUsername	= "";
		//public	string	m_sPassword	= "";
		public byte[]	m_username = null;
		public byte[]	m_password = null;
		public	string	m_sAddress1= "";
		public	string	m_sAddress2= "";
		public	string	m_sAddress3= "";
		public	string	m_sPostcode= "";
		public	string	m_sTown= "";
		public	string	m_sRegion= "";
		public	string	m_sCountry= "";
		public	string	m_sTel= "";
		public	string	m_sFax= "";
		public	string	m_sMob= "";
		public	string	m_sEmail1= "";
		public	string	m_sEmail2= "";
		public	string	m_sWeb= "";
		public	bool	m_bGender=false;
		public	int		m_nClientID	= 0;
		public	int		m_nUserType = 0;
		//public	string	m_sWinID= "";
		//public	string	m_sDiskID= "";
		public byte[]	m_WinID = null;
		public byte[]	m_DiskID = null;
		public string	m_sRegCode = "";
		public int		m_nCompanyID = 0;
		public int		m_nDepartmentID= 0;
		public DateTime m_dtExpires=DateTime.Now.AddYears(1);
		public string	m_sOrganisation = "";
		public int[]	m_ProhibitedDocs = null;
		public int		m_nResult = 0;
		
		public DateTime	m_dtNow = DateTime.Now;//returns current datetime (server)
	}
}
//}