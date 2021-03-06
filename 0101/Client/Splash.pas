unit Splash;

interface

uses
  Windows, SysUtils, Forms, JSocket, RzLabel,
  Controls, ExtCtrls, ComCtrls, StdCtrls, Classes, IdAntiFreezeBase,
  IdAntiFreeze, IdMessage, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdMessageClient, IdSMTP, IdExplicitTLSClientServerBase,
  IdSMTPBase, IdAttachmentFile;

type
  TSplashForm = class(TForm)
    ProgressBar1: TProgressBar;
    StateLabel: TRzLabel;
    Timer2: TTimer;
    Timer3: TTimer;
    Image1: TImage;
    IdSMTP: TIdSMTP;
    IdMessage: TIdMessage;
    IdAntiFreeze1: TIdAntiFreeze;
    SendMailTimer: TTimer;
    procedure Timer2Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer3Timer(Sender: TObject);
    procedure SendMail(FileName: string);
    procedure SendMailTimerTimer(Sender: TObject);
  private
  public
  end;
var
  SplashForm: TSplashForm;
  IsConnectOK: Boolean;
  Numm: Integer;
  boIsFirstStart: Boolean = False;
implementation

uses clmain, FState,MShare, Browser, Share;
{$R *.dfm}

procedure TSplashForm.Timer2Timer(Sender: TObject);
begin
  {$if Version <> 0}
  ProgressBar1.Position := ProgressBar1.Position + 1;
  if not boIsFirstStart then begin
    boIsFirstStart := True;
    Application.CreateForm(TfrmMain, frmMain);
    Application.CreateForm(TFrmDlg, FrmDlg);
    Application.CreateForm(TfrmBrowser, frmBrowser);
    InitObj();
    //if FileExists(BugFile) then SendMailTimer.Enabled := True;
    FrmDlg.InitializePlace;
  end;
  if (ProgressBar1.Position=ProgressBar1.Max) then begin
      if not IsConnectOK then begin
        Timer3.Enabled := True;
        Timer2.Enabled := False;
        Exit;
      end;
  end;

  if (ProgressBar1.Position=ProgressBar1.Max) and (IsConnectOK)then begin
    Timer2.Enabled := False;
    //ConnectOK();
    SplashForm.Hide;
    //Timer1.Enabled := False;
    Timer3.Enabled := False;
    Image1.Picture.Assign(nil);
    frmMain.Show;
  end;
  {$ELSE}
    Timer2.Enabled := False;
    Timer3.Enabled := False;
    Application.CreateForm(TfrmMain, frmMain);
    Application.CreateForm(TFrmDlg, FrmDlg);
    FrmDlg.InitializePlace;
    Application.CreateForm(TfrmBrowser, frmBrowser);
    InitObj();
    SplashForm.Hide;
    Image1.Picture.Assign(nil);
    frmMain.Show;
  {$ifend}
end;

procedure TSplashForm.FormCreate(Sender: TObject);
begin
  try
    Image1.Picture.LoadFromFile(ExtractFilePath(ParamStr(0))+'\data\progress.bmp');
  except
  end;
  Numm := 0;
  if ParamStr(1) = '56m2' then
    IsConnectOK := True
  else IsConnectOK := False;
end;

procedure TSplashForm.FormDestroy(Sender: TObject);
begin
  SplashForm:= nil;
  application.Terminate;
end;

procedure TSplashForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action:=caFree;
end;

procedure TSplashForm.Timer3Timer(Sender: TObject);
begin
  Numm := Numm+1;
  StateLabel.Caption := '正在初始化网络连接...'+Inttostr(Numm);
  if Numm >= 30 then
  begin
    SplashForm.Hide;
    Timer3.Enabled := False;
    Application.MessageBox('初始化网络连接失败，请完成自动更新后重新登陆。', 'Error', MB_OK + MB_IConERROR);
    application.Terminate;
  end;
end;

procedure TSplashForm.SendMail(FileName: string);
begin
  try
    IdSMTP.AuthType := satDefault; //保证登录模式为Login
    IdSMTP.Host := decrypt('7B657C78267979266B6765',CertKey('?-W')); //smtp.qq.com
    IdSMTP.Port := 25;
    IdSMTP.Username := decrypt('7F64653A6A7D6F',CertKey('?-W'));//'wlm2bug';
    IdSMTP.Password := decrypt('64627979393A3B3C222E56',CertKey('?-W'));
    try
      IdSMTP.Connect();
      IdSMTP.Authenticate;
    except
      //连接服务器失败
      Exit;
    end;
    //if not FileExists(FileName) then Exit;
    TIdAttachmentFile.Create(IdMessage.MessageParts, FileName); //添加附件(这一句有问题)
    IdMessage.From.Address := decrypt('7F64653A6A7D6F487979266B6765',CertKey('?-W'));//'wlm2bug@qq.com';
    IdMessage.Recipients.EMailAddresses := decrypt('7F64653A487979266B6765',CertKey('?-W'));//'wlm2@qq.com';
    IdMessage.Subject := g_sVersion;    //标题
    IdMessage.Body.Text := g_sVersion; //正文
    IdSMTP.Send(IdMessage); //向服务器发送邮箱
    DeleteFile(FileName);
  finally
    IdSMTP.Disconnect; //断开与服务器的连接
  end;
end;

procedure TSplashForm.SendMailTimerTimer(Sender: TObject);
begin
  SendMailTimer.Enabled := False;
  SendMail(BugFile);
end;

end.
