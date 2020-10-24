unit Unit1;

{$mode Delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  Windows, Messages, Variants, WinSock, Sockets, StdCtrls, syncobjs;

const
 WM_SSocketEvent=WM_User+1;
 WM_CSocketEvent=WM_User+2;

type

  TAsyncStyle = (asRead, asWrite, asOOB, asAccept, asConnect, asClose);
  TAsyncStyles = set of TAsyncStyle;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FTempStream: TMemoryStream;
  public
    ClntSock   :TSocket;
    function CheckSocketResult(ResultCode: Integer; const Op: string): Integer;
    procedure WMSSocketEvent(var Msg:TMessage);message WM_SSocketEvent;
    procedure WMCSocketEvent(var Msg:TMessage);message WM_CSocketEvent;
    procedure WriteLn(st: String);
    procedure DebugLn(st: String);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

const
  addrs = '192.168.56.102';
  port = 8097;

{ TForm1 }

function TForm1.CheckSocketResult(ResultCode: Integer; const Op: string): Integer;
begin
  if ResultCode <> 0 then
  begin
    Result := WSAGetLastError;
    if Result <> WSAEWOULDBLOCK then
      WriteLn('Err!!: ' + Op);
  end else Result := 0;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  Data:TWSAData;
begin
  FTempStream := TMemoryStream.Create;
  Memo1.Clear;
  WSAStartup($101, Data);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  Addr:TSockAddr;
  FASyncStyles: TASyncStyles;
begin
  ClntSock := fpsocket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  FASyncStyles := [asRead, asWrite, asConnect, asClose];
  WSAAsyncSelect(ClntSock,Handle, WM_SSocketEvent, Longint(Byte(FAsyncStyles)));
  Addr.sin_family := AF_Inet;
  Addr.sin_addr := StrToNetAddr(addrs);
  Addr.sin_port := htons(port);
  CheckSocketResult(fpConnect(ClntSock,@Addr,SizeOf(Addr)), 'fpConnect');
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
 WSACleanup;
 FTempStream.Free;
end;

procedure TForm1.WMCSocketEvent(var Msg: TMessage);
begin
  ShowMessage('sdfssdf');
end;

procedure TForm1.WriteLn(st: String);
begin
  Memo1.Lines.Add(st);
end;

procedure TForm1.DebugLn(st: String);
begin
  Memo1.Lines.Add('D: ' + st);
end;

procedure TForm1.WMSSocketEvent(var Msg: TMessage);
var
  Sock:TSocket;
  SockError:Integer;
  procedure Read();
  var
    i, j:Integer;
    buf: PAnsiChar;
  begin
    DebugLn('Read');
    ioctlsocket(sock, FIONREAD, Longint(i));
    //i := 1000; //to try
    GetMem(buf, i);
    j := i;
    try
      try
        while j > 0 do
        begin
          j := fprecv(sock, buf, i, 0);
          FTempStream.Write(buf^, j);
        end;
      except
        WriteLn('Data receive error.')
      end;
    finally
      FreeMem(buf);
    end;
  end;

  procedure Accept();
  begin
    DebugLn('Accept');
    fpAccept(Sock,nil,nil);
  end;

  procedure Close();
  begin
    DebugLn('Close in buf: ' + IntToStr(FTempStream.Size));
    Shutdown(Sock,SHUT_RDWR);
    CloseSocket(Sock);
    FTempStream.Position:=0;
    WriteLn('Read:' + IntToStr(FTempStream.Size));
    FTempStream.Clear;
  end;

begin
  Sock:=TSocket(Msg.WParam);
  SockError:=WSAGetSelectError(Msg.lParam);
  if SockError<>0 then
  begin
    WriteLn('SockError = 0! ERROR');
    CloseSocket(Sock);
    Exit;
  end;
  case WSAGetSelectEvent(Msg.lParam) of
    FD_Read: Read();
    FD_Accept: Accept();
    FD_Close: Close();
    FD_WRITE: DebugLn('FD_WRITE');
    FD_OOB: DebugLn('FD_OOB');
    FD_CONNECT: DebugLn('FD_CONNECT');
  end;
end;

end.

