{------------------------------------------------------------------------------}
{ ��Ԫ����: Wil.pas                                                            }
{                                                                              }
{ ��Ԫ����: ���� (QQ:272987775       Email:272987775@QQ.com)                   }
{ ��������: 2007-10-28 20:30:00                                                }
{                                                                              }
{ ���ܽ���:                                                                    }
{   ����2 Wil �ļ���ȡ��Ԫ                                                     }
{                                                                              }
{ ʹ��˵��:                                                                    }
{                                                                              }
{   WIL λͼ�ļ�: �� �ļ�ͷ+��ɫ��(256ɫ)+(TImageInfo+λͼ Bits)*N�� ���      }
{   WIX �����ļ�: ʵ���Ͼ���һ���ļ�ͷ+ָ������, ָ��ָ�� TImageInfo �ṹ      }
{                                                                              }
{ ������ʷ:                                                                    }
{                                                                              }
{ �д�����:                                                                    }
{                                                                              }
{    WIL �ĵ�ɫ���ǲ��Ƕ���һ���ģ�����ǣ������ʡ��                          }
{    ע�⣺ WIL �����ݸ�ʽ���嶼��û�� pack �� record                          }
{                                                                              }
{    Weapon.wix ��������: �����ļ�ͷ���õ�ͼƬ����Ϊ 40856, ʵ���ܶ���������   }
{      Ϊ 40855, ����Դ��������������е�ԭ������û�м��ɶ���������.         }
{      ������Ҫ�ؽ�����. Ŀǰ�Ľ���������� LoadIndexFile �и��ݶ�����ʵ����   }
{      �ݶ� FImageCount ��������.                                              }
{                                                                              }
{------------------------------------------------------------------------------}

unit WIL;

interface

uses
  Windows, Classes, Graphics, SysUtils, DXDraws, 
  DirectX, DIB, wmUtil, HUtil32;
{------------------------------------------------------------------------------}
// WIL ��������
{------------------------------------------------------------------------------}
var
  g_boUseDIBSurface  :Boolean = FALSE;// �Ƿ��ڴ��� WIL Surface ʱʹ�� DIB ����
                                  // ���ֱ��ʹ�� WIL �ļ��е�λͼ Bits �����������ɫ
                                  // ��ʾ����ȷ���ڴ���Դ�����еĽ��Ҳ����ˡ�
  
{------------------------------------------------------------------------------}
// WIL �ļ���ʽ����
{------------------------------------------------------------------------------}
type
// WIL �ļ�ͷ��ʽ (56Byte)
  TLibType = (ltLoadBmp, ltLoadMemory, ltLoadMunual, ltUseCache);


  TBmpImage = record
    Bmp           :TBitmap;
    dwLatestTime  :LongWord;
  end;
  pTBmpImage = ^TBmpImage;

   TBmpImageArr  = array[0..MaxListSize div 4] of TBmpImage;
   TDxImageArr   = array[0..MaxListSize div 4] of TDxImage;
   PTBmpImageArr = ^TBmpImageArr;
   PTDxImageArr  = ^TDxImageArr;
{------------------------------------------------------------------------------}
// TWilFile class
{------------------------------------------------------------------------------}
   TWMImages = class (TComponent)
   private
      FFileName: String;              //0x24  // WIL �ļ���
      FImageCount: integer;           //0x28  // ͼƬ����
      FLibType: TLibType;             //0x2C  //ͼ��װ�ط�ʽ
      FDxDraw: TDxDraw;               //0x30
      FDDraw: TDirectDraw;            //0x34
      //FMaxMemorySize: integer;        //0x38
      btVersion:Byte;                 //0x3C
      m_bt458    :Byte;
      FAppr:Word;
      procedure LoadAllData;
      procedure LoadIndex (idxfile: string);
      procedure LoadDxImage (position: integer; pdximg: PTDxImage);
      procedure LoadBmpImage (position: integer; pbmpimg: PTBmpImage);
      procedure FreeOldMemorys;
      function  FGetImageSurface (index: integer): TDirectDrawSurface;
      procedure FSetDxDraw (fdd: TDxDraw);
      procedure FreeOldBmps;
      function  FGetImageBitmap (index: integer): TBitmap;
   protected
      lsDib: TDib;              //0x40
      m_dwMemChecktTick: LongWord;   //0x44
   public
      m_ImgArr    :pTDxImageArr;     //0x48
      m_BmpArr    :pTBmpImageArr;    //0x4C
      m_IndexList :TList;         //0x50
      m_FileStream: TFileStream;      //0x54
      MainPalette: TRgbQuads;
      constructor Create (AOwner: TComponent); override;
      destructor Destroy; override;

      procedure Initialize;
      procedure Finalize;
      procedure ClearCache;
      procedure LoadPalette;
      procedure FreeBitmap (index: integer);
      function  GetImage (index: integer; var px, py: integer): TDirectDrawSurface;
      function  GetCachedImage (index: integer; var px, py: integer): TDirectDrawSurface;
      function  GetCachedSurface (index: integer): TDirectDrawSurface;
      function  GetCachedBitmap (index: integer): TBitmap;
      property Images[index: integer]: TDirectDrawSurface read FGetImageSurface;
    	property Bitmaps[Index: Integer]: TBitmap read FGetImageBitmap;
      property DDraw: TDirectDraw read FDDraw write FDDraw;
   published
      property FileName: string read FFileName write FFileName;
      property ImageCount: integer read FImageCount;
      property DxDraw: TDxDraw read FDxDraw write FSetDxDraw;
      property LibType: TLibType read FLibType write FLibType;
      //property MaxMemorySize: integer read FMaxMemorySize write FMaxMemorySize;
      property Appr:Word read FAppr write FAppr;
   end;

procedure Register;


implementation
procedure Register;
begin
   RegisterComponents('MirGame', [TWmImages]);
end;

constructor TWMImages.Create (AOwner: TComponent);
begin
   inherited Create (AOwner);
   FFileName := '';
   FLibType := ltLoadBmp;
   FImageCount := 0;
   //FMaxMemorySize := 1024*1000; //1M

   FDDraw := nil;
   FDxDraw := nil;
   m_FileStream := nil;
   m_ImgArr := nil;
   m_BmpArr := nil;
   m_IndexList := TList.Create;
   lsDib := TDib.Create;
   lsDib.BitCount := 8;

   m_dwMemChecktTick := GetTickCount;
   btVersion:=0;
   m_bt458:=0;   
end;

destructor TWMImages.Destroy;
begin
   m_IndexList.Free;
   if m_FileStream <> nil then m_FileStream.Free;
   lsDib.Free;
   inherited Destroy;
end;

procedure TWMImages.Initialize;
var
  Idxfile: String;
  Header :TWMImageHeader;
begin
   if not (csDesigning in ComponentState) then begin
      if FFileName = '' then begin
         //raise Exception.Create ('FileName not assigned..');
         Exit;
      end;
      if (LibType <> ltLoadBmp) and (FDDraw = nil) then begin
         //raise Exception.Create ('DDraw not assigned..');
         Exit;
      end;
      if FileExists (FFileName) then begin
         if m_FileStream = nil then
            m_FileStream := TFileStream.Create (FFileName, fmOpenRead or fmShareDenyNone);
         m_FileStream.Read (Header, SizeOf(TWMImageHeader));
         if header.VerFlag = 0 then begin
           btVersion:=1;
           m_FileStream.Seek(-4,soFromCurrent);
         end;

         FImageCount := Header.ImageCount;
         if LibType = ltLoadBmp then begin
            m_BmpArr := AllocMem (SizeOf(TBmpImage) * FImageCount);
            if m_BmpArr = nil then
               raise Exception.Create (self.Name + ' BmpArr = nil');
         end else begin
            m_ImgArr:=AllocMem(SizeOf(TDxImage) * FImageCount);
            if m_ImgArr = nil then
               raise Exception.Create (self.Name + ' ImgArr = nil');
         end;
         //�����ļ�
         idxfile := ExtractFilePath(FFileName) + ExtractFileNameOnly(FFileName) + '.WIX';
         LoadPalette;
         if LibType = ltLoadMemory then
            LoadAllData
         else begin
            LoadIndex (idxfile);
         end;
      end else begin
//         MessageDlg (FFileName + ' Cannot find file.', mtWarning, [mbOk], 0);
      end;
   end;
end;

procedure TWMImages.Finalize;
var
   i: integer;
begin
//�ͷ�װ�ص�����ͼƬ
   //if FImageCount > 0 then begin//20080629
     for i:=0 to FImageCount-1 do begin
        if m_ImgArr[i].Surface <> nil then begin
           m_ImgArr[i].Surface.Free;
           m_ImgArr[i].Surface := nil;
        end;
     end;
   //end;
   if m_FileStream <> nil then
      FreeAndNil(m_FileStream);

   if FImageCount > 0 then begin
     if LibType = ltLoadBmp then begin //20080718�ͷ��ڴ�
       FreeMem(m_BmpArr);
     end else begin
       FreeMem(m_ImgArr);
     end;
   end;
end;

//װ��ͼƬ���ڴ棬��Ҫ�����ڴ棡
procedure TWMImages.LoadAllData;
var
   i: integer;
   imgi: TWMImageInfo;
   dib: TDIB;
   dximg: TDxImage;
begin
   dib := TDIB.Create;
   if FImageCount > 0 then begin//20080629
     for i:=0 to FImageCount-1 do begin
     if btVersion <> 0 then m_FileStream.Read (imgi, sizeof(TWMImageInfo) - 4)
     else m_FileStream.Read (imgi, sizeof(TWMImageInfo));

        dib.Width := imgi.nWidth;
        dib.Height := imgi.nHeight;
        dib.ColorTable := MainPalette;
        dib.UpdatePalette;
        m_FileStream.Read (dib.PBits^, imgi.nWidth * imgi.nHeight);

        dximg.nPx := imgi.px;
        dximg.nPy := imgi.py;
        dximg.surface := TDirectDrawSurface.Create (FDDraw);
        dximg.surface.SystemMemory := True;
        dximg.surface.SetSize (imgi.nWidth, imgi.nHeight);
        dximg.surface.Canvas.Draw (0, 0, dib);
        dximg.surface.Canvas.Release; 
        dib.Clear; //FreeImage;

        dximg.surface.TransparentColor := 0;
        m_ImgArr[i] := dximg;
        FreeAndNil(dximg.surface); //20080719����
     end;
   end;
   dib.Free;
end;
//��WIL�ļ���װ�ص�ɫ��
procedure TWMImages.LoadPalette;
{var
   Entries: TPaletteEntries;  }
begin
   if btVersion <> 0 then
     m_FileStream.Seek (sizeof(TWMImageHeader) - 4, 0)
   else
     m_FileStream.Seek (sizeof(TWMImageHeader), 0);
     
   m_FileStream.Read (MainPalette, sizeof(TRgbQuad) * 256); //
end;



procedure TWMImages.LoadIndex (idxfile: string);
var
   fhandle, i, value: integer;
   header: TWMIndexHeader;
   //pidx: PTWMIndexInfo;  //20080718ע���ͷ��ڴ�
   pvalue: PInteger;
begin
   m_IndexList.Clear;
   if FileExists (idxfile) then begin
      fhandle := FileOpen (idxfile, fmOpenRead or fmShareDenyNone);
      if fhandle > 0 then begin
         if btVersion <> 0 then
           FileRead (fhandle, header, sizeof(TWMIndexHeader) - 4)
         else
           FileRead (fhandle, header, sizeof(TWMIndexHeader));

         GetMem (pvalue, 4*header.IndexCount);
         FileRead (fhandle, pvalue^, 4*header.IndexCount);
         if header.IndexCount > 0 then //20080629
         for i:=0 to header.IndexCount-1 do begin
            value := PInteger(integer(pvalue) + 4*i)^;
            m_IndexList.Add (pointer(value));
         end;
         FreeMem(pvalue);
         FileClose (fhandle);
      end;
   end;
end;

{----------------- Private Variables ---------------------}

function  TWMImages.FGetImageSurface (index: integer): TDirectDrawSurface;
begin
   Result := nil;
   if LibType = ltUseCache then begin
      Result := GetCachedSurface (index);
   end else
   if LibType = ltLoadMemory then begin
     if (index >= 0) and (index < ImageCount) then
       Result := m_ImgArr[index].Surface;
   end;
         
end;

function  TWMImages.FGetImageBitmap (index: integer): TBitmap;
begin
   Result:=nil;
   if LibType <> ltLoadBmp then exit;
   Result := GetCachedBitmap (index);
end;

procedure TWMImages.FSetDxDraw (fdd: TDxDraw);
begin
   FDxDraw := fdd;
end;

// *** DirectDrawSurface Functions

procedure TWMImages.LoadDxImage (position: integer; pdximg: PTDxImage);
var
   imginfo: TWMImageInfo;
   ddsd: TDDSurfaceDesc;
   SBits, PSrc, DBits: PByte;
   n, slen: integer;
begin
   m_FileStream.Seek (position, 0);
   if btVersion <> 0 then m_FileStream.Read (imginfo, SizeOf(TWMImageInfo)-4)
   else m_FileStream.Read (imginfo, SizeOf(TWMImageInfo));


   if g_boUseDIBSurface then begin //DIB
      //��ȫ��ʱ
      try
      lsDib.Clear;
      lsDib.Width := imginfo.nWidth;
      lsDib.Height := imginfo.nHeight;
      except
      end;
      lsDib.ColorTable := MainPalette;
      lsDib.UpdatePalette;
      DBits := lsDib.PBits;
      m_FileStream.Read (DBits^, imginfo.nWidth * imgInfo.nHeight);

      pdximg.nPx := imginfo.px;
      pdximg.nPy := imginfo.py;
      pdximg.surface := TDirectDrawSurface.Create (FDDraw);
      pdximg.surface.SystemMemory := TRUE;
      pdximg.surface.SetSize (imginfo.nWidth, imginfo.nHeight);
      pdximg.surface.Canvas.Draw (0, 0, lsDib);
      pdximg.surface.Canvas.Release;

      pdximg.surface.TransparentColor := 0;
   end else begin //
      //ȫ��ʱ
     try   
      slen  := WidthBytes(imginfo.nWidth);
      GetMem (PSrc, slen * imgInfo.nHeight);
     // SBits := PSrc;  //20080718ע���ͷ��ڴ�
      m_FileStream.Read (PSrc^, slen * imgInfo.nHeight);
      
         pdximg.surface := TDirectDrawSurface.Create (FDDraw);
         pdximg.surface.SystemMemory := TRUE;
         pdximg.surface.SetSize (slen, imginfo.nHeight);
         //pdximg.surface.Palette := MainSurfacePalette;

         pdximg.nPx := imginfo.px;
         pdximg.nPy := imginfo.py;
         ddsd.dwSize := SizeOf(ddsd);

         pdximg.surface.Lock (TRect(nil^), ddsd);
         DBits := ddsd.lpSurface;
         if imginfo.nHeight > 0 then //20080629
         for n:=imginfo.nHeight - 1 downto 0 do begin
            SBits := PByte (Integer(PSrc) + slen * n);
            Move(SBits^, DBits^, slen);
            Inc (integer(DBits), ddsd.lPitch);
         end;
         pdximg.surface.TransparentColor := 0;
      finally
        pdximg.surface.UnLock();
        FreeMem(PSrc); //20080719�޸�
      end;
   end;
end;

procedure TWMImages.LoadBmpImage (position: integer; pbmpimg: PTBmpImage);
var
   imginfo: TWMImageInfo;
   DBits: PByte;
begin
   m_FileStream.Seek (position, 0);
   m_FileStream.Read (imginfo, sizeof(TWMImageInfo)-4);

   lsDib.Width := imginfo.nWidth;
   lsDib.Height := imginfo.nHeight;
   lsDib.ColorTable := MainPalette;
   lsDib.UpdatePalette;
   DBits := lsDib.PBits;
   m_FileStream.Read (DBits^, imginfo.nWidth * imgInfo.nHeight);

   pbmpimg.bmp := TBitmap.Create;
   pbmpimg.bmp.Width := lsDib.Width;
   pbmpimg.bmp.Height := lsDib.Height;
   pbmpimg.bmp.Canvas.Draw (0, 0, lsDib);
   lsDib.Clear;
end;

procedure TWMImages.ClearCache;
var
   i: integer;
begin
   if ImageCount > 0 then //20080629
   for i:=0 to ImageCount - 1 do begin
      if m_ImgArr[i].Surface <> nil then begin
         m_ImgArr[i].Surface.Free;
         m_ImgArr[i].Surface := nil;
      end;
   end;
   //MemorySize := 0;
end;

function  TWMImages.GetImage (index: integer; var px, py: integer): TDirectDrawSurface;
begin
   if (index >= 0) and (index < ImageCount) then begin
      px := m_ImgArr[index].nPx;
      py := m_ImgArr[index].nPy;
      Result := m_ImgArr[index].surface;
   end else
      Result := nil;
end;

{--------------- BMP functions ----------------}

procedure TWMImages.FreeOldBmps;
var
   i, ntime{, curtime}: integer;
begin
   ntime := 0;
   if ImageCount > 0 then //20080629
   for i:=0 to ImageCount-1 do begin
//      curtime := GetTickCount;
      if m_BmpArr[i].Bmp <> nil then begin
         if GetTickCount - m_BmpArr[i].dwLatestTime > 5000 then begin
            m_BmpArr[i].Bmp.Free;
            m_BmpArr[i].Bmp := nil;
         end else begin
            if GetTickCount - m_BmpArr[i].dwLatestTime > ntime then begin
               ntime := GetTickCount - m_BmpArr[i].dwLatestTime;
            end;
         end;
      end;
   end;
end;

procedure TWMImages.FreeBitmap (index: integer);
begin
   if (index >= 0) and (index < ImageCount) then begin
      if m_BmpArr[index].Bmp <> nil then begin
         //MemorySize  := MemorySize - BmpArr[index].Bmp.Width * BmpArr[index].Bmp.Height;
         //if MemorySize < 0 then MemorySize := 0;
         m_BmpArr[index].Bmp.FreeImage;
         m_BmpArr[index].Bmp.Free;
         m_BmpArr[index].Bmp := nil;
      end;
   end;
end;


//������ ĳ�� ����
procedure TWMImages.FreeOldMemorys;
var
   i: integer;
begin
   if ImageCount > 0 then //20080629
   for i:=0 to ImageCount-1 do begin
      if m_ImgArr[i].Surface <> nil then begin
         if GetTickCount - m_ImgArr[i].dwLatestTime > 5 * 60 * 1000 then begin
            m_ImgArr[i].Surface.Free;
            m_ImgArr[i].Surface := nil;
            //FreeAndNil(m_ImgArr[i].Surface); //20081719�޸�
         end;
      end;
   end;
end;

//Cache�� �̿���
function  TWMImages.GetCachedSurface (index: integer): TDirectDrawSurface;
var
  nPosition:Integer;
  //nErrCode:Integer;
begin
  Result := nil;
  //nErrCode:=0;
  try
  if (index < 0) or (index >= ImageCount) then exit;
  if GetTickCount - m_dwMemChecktTick > 10000 then  begin
      m_dwMemChecktTick := GetTickCount;
      //if MemorySize > FMaxMemorySize then begin
      FreeOldMemorys;
      //end;
   end;
   //nErrCode:=1;
   if m_ImgArr[index].Surface = nil then begin //cache�Ǿ� ���� ����. ���� �о����.
      if index < m_IndexList.Count then begin
         nPosition:= Integer(m_IndexList[index]);
         LoadDxImage (nPosition, @m_ImgArr[index]);
         m_ImgArr[index].dwLatestTime := GetTickCount;
         //nErrCode:=2;
         Result := m_ImgArr[index].Surface;
         //MemorySize := MemorySize + ImgArr[index].Surface.Width * ImgArr[index].Surface.Height;
      end;
   end else begin
      m_ImgArr[index].dwLatestTime := GetTickCount;
      //nErrCode:=3;
      Result := m_ImgArr[index].Surface;
   end;

   except
    //DebugOutStr ('GetCachedSurface 3 Index: ' + IntToStr(index) + ' Error Code: ' + IntToStr(nErrCode));
   end;
end;

function  TWMImages.GetCachedImage (index: integer; var px, py: integer): TDirectDrawSurface;
var
   position: integer;
   //nErrCode:Integer;
begin
   Result := nil;
   //nErrCode:=0;
   try
   if (index < 0) or (index >= ImageCount) then Exit;
   if GetTickCount - m_dwMemChecktTick > 10000 then  begin
      m_dwMemChecktTick := GetTickCount;
      //if MemorySize > FMaxMemorySize then begin
      FreeOldMemorys;
      //end;
   end;
   //nErrCode:=1;
   if m_ImgArr[index].Surface = nil then begin //cache
      if index < m_IndexList.Count then begin
         position := Integer(m_IndexList[index]);
         LoadDxImage (position, @m_ImgArr[index]);
         m_ImgArr[index].dwLatestTime := GetTickCount;
         px := m_ImgArr[index].nPx;
         py := m_ImgArr[index].nPy;
         Result := m_ImgArr[index].Surface;
         //MemorySize := MemorySize + ImgArr[index].Surface.Width * ImgArr[index].Surface.Height;
      end;

   end else begin
      m_ImgArr[index].dwLatestTime := GetTickCount;
      px := m_ImgArr[index].nPx;
      py := m_ImgArr[index].nPy;
      Result := m_ImgArr[index].Surface;
   end;
   except
    //DebugOutStr ('GetCachedImage 3 Index: ' + IntToStr(index) + ' Error Code: ' + IntToStr(nErrCode));
   end;
end;

function  TWMImages.GetCachedBitmap (index: integer): TBitmap;
var
   position: integer;
begin
   Result := nil;
   if (index < 0) or (index >= ImageCount) then exit;
   if m_BmpArr[index].Bmp = nil then begin //cache�Ǿ� ���� ����. ���� �о����.
      if index < m_IndexList.Count then begin
         position := Integer(m_IndexList[index]);
         LoadBmpImage (position, @m_BmpArr[index]);
         m_BmpArr[index].dwLatestTime := GetTickCount;
         Result := m_BmpArr[index].Bmp;
         //MemorySize := MemorySize + BmpArr[index].Bmp.Width * BmpArr[index].Bmp.Height;
         //if (MemorySize > FMaxMemorySize) then begin
         FreeOldBmps;
         //end;
      end;
   end else begin
      m_BmpArr[index].dwLatestTime:=GetTickCount;
      Result := m_BmpArr[index].Bmp;
   end;
end;






end.