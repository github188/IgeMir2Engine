(**************************************************)
(*                                                *)
(*     Advanced Encryption Standard (AES)         *)
(*     Interface Unit v1.3                        *)
(*                                                *)
(*                                                *)
(*     Copyright (c) 2002 Jorlen Young            *)
(*                                                *)
(*                                                *)
(*                                                *)
(*˵����                                          *)
(*                                                *)
(*   ���� ElASE.pas ��Ԫ��װ                      *)
(*                                                *)
(*   ����һ�� AES �����㷨�ı�׼�ӿڡ�            *)
(*                                                *)
(*                                                *)
(*   ���ߣ�������      2004.12.04                 *)
(*                                                *)
(*   ֧�� 128 / 192 / 256 λ���ܳ�                *)                
(*   Ĭ������°��� 128 λ�ܳײ���                *)
(*                                                *)
(**************************************************)

unit AES;                  

interface

uses
  SysUtils, Classes, Math, ElAES;

type
  TKeyBit = (kb128, kb192, kb256);

function StrToHex(Value: string): string;
function HexToStr(Value: string): string;
function EncryptString(Value: string; Key: string;
  KeyBit: TKeyBit = kb128): string;
function DecryptString(Value: string; Key: string;
  KeyBit: TKeyBit = kb128): string;

implementation

function StrToHex(Value: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Value) do
    Result := Result + IntToHex(Ord(Value[I]), 2);
end;

function HexToStr(Value: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(Value) do
  begin
    if ((I mod 2) = 1) then
      Result := Result + Chr(StrToInt('0x'+ Copy(Value, I, 2)));
  end;
end;

{  --  �ַ������ܺ��� Ĭ�ϰ��� 128 λ�ܳ׼��� --  }
function EncryptString(Value: string; Key: string;
  KeyBit: TKeyBit = kb128): string;
var
  SS, DS: TStringStream;
  Size: Int64;
  AESKey128: TAESKey128;
  AESKey192: TAESKey192;
  AESKey256: TAESKey256;
begin
  Result := '';
  SS := TStringStream.Create(Value);
  DS := TStringStream.Create('');
  try
    Size := SS.Size;
    DS.WriteBuffer(Size, SizeOf(Size));
    {  --  128 λ�ܳ���󳤶�Ϊ 16 ���ַ� --  }
    if KeyBit = kb128 then
    begin
      FillChar(AESKey128, SizeOf(AESKey128), 0 );
      Move(PChar(Key)^, AESKey128, Min(SizeOf(AESKey128), Length(Key)));
      EncryptAESStreamECB(SS, 0, AESKey128, DS);
    end;
    {  --  192 λ�ܳ���󳤶�Ϊ 24 ���ַ� --  }
    if KeyBit = kb192 then
    begin
      FillChar(AESKey192, SizeOf(AESKey192), 0 );
      Move(PChar(Key)^, AESKey192, Min(SizeOf(AESKey192), Length(Key)));
      EncryptAESStreamECB(SS, 0, AESKey192, DS);
    end;
    {  --  256 λ�ܳ���󳤶�Ϊ 32 ���ַ� --  }
    if KeyBit = kb256 then
    begin
      FillChar(AESKey256, SizeOf(AESKey256), 0 );
      Move(PChar(Key)^, AESKey256, Min(SizeOf(AESKey256), Length(Key)));
      EncryptAESStreamECB(SS, 0, AESKey256, DS);
    end;
    Result := StrToHex(DS.DataString);
  finally
    SS.Free;
    DS.Free;
  end;
end;

{  --  �ַ������ܺ��� Ĭ�ϰ��� 128 λ�ܳ׽��� --  }
function DecryptString(Value: string; Key: string;
  KeyBit: TKeyBit = kb128): string;
var
  SS, DS: TStringStream;
  Size: Int64;
  AESKey128: TAESKey128;
  AESKey192: TAESKey192;
  AESKey256: TAESKey256;
begin
  Result := '';
  SS := TStringStream.Create(HexToStr(Value));
  DS := TStringStream.Create('');
  try
    Size := SS.Size;
    SS.ReadBuffer(Size, SizeOf(Size));
    {  --  128 λ�ܳ���󳤶�Ϊ 16 ���ַ� --  }
    if KeyBit = kb128 then
    begin
      FillChar(AESKey128, SizeOf(AESKey128), 0 );
      Move(PChar(Key)^, AESKey128, Min(SizeOf(AESKey128), Length(Key)));
      DecryptAESStreamECB(SS, SS.Size - SS.Position, AESKey128, DS);
    end;
    {  --  192 λ�ܳ���󳤶�Ϊ 24 ���ַ� --  }
    if KeyBit = kb192 then
    begin
      FillChar(AESKey192, SizeOf(AESKey192), 0 );
      Move(PChar(Key)^, AESKey192, Min(SizeOf(AESKey192), Length(Key)));
      DecryptAESStreamECB(SS, SS.Size - SS.Position, AESKey192, DS);
    end;
    {  --  256 λ�ܳ���󳤶�Ϊ 32 ���ַ� --  }
    if KeyBit = kb256 then
    begin
      FillChar(AESKey256, SizeOf(AESKey256), 0 );
      Move(PChar(Key)^, AESKey256, Min(SizeOf(AESKey256), Length(Key)));
      DecryptAESStreamECB(SS, SS.Size - SS.Position, AESKey256, DS);
    end;
    Result := DS.DataString;
  finally
    SS.Free;
    DS.Free;
  end;
end;


end.