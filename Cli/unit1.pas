unit Unit1;

{$mode Delphi}{$H+}

interface

uses
  {$IFDEF Linux}
  BaseUnix, Unix,
  {$ELSE}
  WinSock, ssockets,
  {$ENDIF}
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  frxServerClient, frxServer, frxHTTPClient, ctypes, Sockets,
  LCLType, Messages, LMessages, LCLIntf,
  Windows ;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure WriteLn(s: String);
begin
  Form1.Memo1.Lines.Add(s);
end;

procedure DieWithError(s: String);
begin
  Form1.Memo1.Lines.Add('Crit. Error:' + s);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  sock: cint;                      { Socket descriptor }
  echoServAddr: TSockAddr;         { Echo server address }
  echoServPort: cushort;           { Echo server port }
  servIP: PChar;                   { Server IP address (dotted quad) }
  i, j, ch:Integer;
  buf: PAnsiChar;
  FTempStream: TMemoryStream;
begin
  FTempStream := TMemoryStream.Create;
  servIP := '192.168.56.102';
  echoServPort := 8097;

  sock := fpsocket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  if sock < 0 then
  begin
    DieWithError('socket() failed');
    Exit;
  end;

  echoServAddr.sin_family      := AF_INET;
  echoServAddr.sin_addr := StrToNetAddr(servIP);
  echoServAddr.sin_port        := htons(echoServPort);

  if (fpconnect(sock, @echoServAddr, sizeof(echoServAddr)) < 0) then
  begin
    DieWithError('connect() failed');
    Exit;
  end;

  for ch := 0 to 100 do
  begin
    ioctlsocket(sock, FIONREAD, Longint(i));
    if (i > 0) then
    begin
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
    Sleep(10);
  end;
  FTempStream.Position := 0;
  WriteLn(IntToStr(FTempStream.Size));
  closesocket(sock);
  FTempStream.Free;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to 20 do
    Button1.Click;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Memo1.Clear;
end;

end.

