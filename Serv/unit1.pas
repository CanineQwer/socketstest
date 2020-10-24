unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Sockets,
  {$IFDEF Windows}
  Windows ,winsock2, WinSock,
  {$ELSE}
  BaseUnix, Unix, cNetDB, termio,
  {$ENDIF}
  Forms, LCLType, Messages, Classes, Registry,
  syncobjs, SysUtils, resolve,FileUtil, LResources, Controls,
  Graphics, Dialogs,ComCtrls, LMessages, ExtCtrls, StdCtrls, LCLIntf,
  ctypes,
  Buttons, LCLProc;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
  private

  public
    procedure Writeln(s: String);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }
{$IFNDEF Windowss}
const
  INVALID_SOCKET = TSocket(NOT(0));
{$ENDIF}
var
  vListenSocket,vSocket : TSocket;
  vSockAddr : TSockAddr;

const
  servIP = '192.168.56.102';
  cPort = 8097;

procedure TForm1.Writeln(s: String);
begin
  Memo1.Lines.Add(s);
end;

{$IFDEF Linux}
function inet_addr(cp:pchar):cardinal;
begin
  Result := StrToNetAddr(cp).s_addr;
end;

function IoctlSocket(s: TSocket; cmd: DWORD; var arg: integer): Integer;
begin
  Result := fpIoctl(s, cmd, @arg);
end;
{$ENDIF}

procedure TForm1.Button1Click(Sender: TObject);
var
  FSendStream: TStringStream;
  Blocking: Integer;
  i: Integer;
begin
  FSendStream := TStringStream.Create;
  for i := 0 to 1000000 do
    FSendStream.WriteString(IntToStr(i) + ', ');
  Writeln('Starting application...');
  vListenSocket := fpsocket(PF_INET, SOCK_STREAM, IPPROTO_IP);
  Writeln(format('Creating socket on port [%d].', [cPort]));
  if (vListenSocket = INVALID_SOCKET) then
    Exit;
  vSockAddr.sin_family := PF_INET;
  vSockAddr.sin_addr.s_addr := inet_addr(PAnsiChar(AnsiString(servIP)));
  vSockAddr.sin_port := htons(cPort);
  Writeln('Binding socket...');
  if fpbind(vListenSocket,@vSockAddr,SizeOf(vSockAddr)) <> 0 then
  begin
    Writeln('error = ' + IntToStR(SocketError));
    Exit;
  end
  else
    WriteLn('Good');
  Blocking := 0;
  ioctlsocket(vListenSocket, FIONBIO, Blocking);
  if fplisten(vListenSocket,SOMAXCONN) <> 0 then
    Exit;
  Writeln('Socket status: listening.');
  repeat
    vSocket := fpaccept(vListenSocket,nil,nil);
    if (vSocket = INVALID_SOCKET) then exit;
    if fpsend(vSocket, Pointer(Pointer(FSendStream.Memory)), FSendStream.Size, 0) <> FSendStream.Size then
    begin
      Writeln('some data was not sent');
      Exit;
    end;
    closesocket(vSocket);
  until false;
  closesocket(vListenSocket);
end;

end.
