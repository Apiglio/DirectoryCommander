unit frame_fileselection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, Menus, Windows,
  LazUTF8, DC_Operation;

type

  { TFileSelectionFrame }

  TFileSelectionFrame = class(TFrame)
    ListBox: TListBox;
    MenuItem_SelWin_Open: TMenuItem;
    PopupMenu_SelWin: TPopupMenu;
    procedure ListBoxEnter(Sender: TObject);
    procedure ListBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure ListBoxKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MenuItem_SelWin_OpenClick(Sender: TObject);
  private
    CanOpen:boolean;

  public
    procedure Add(str:string);
    procedure Clear;
    procedure Sort;

  end;

implementation

{$R *.lfm}




procedure TFileSelectionFrame.MenuItem_SelWin_OpenClick(Sender: TObject);
begin
  /////
end;

procedure TFileSelectionFrame.ListBoxEnter(Sender: TObject);
begin
  /////ShowMessage((Sender as TListBox).GetSelectedText);
end;

procedure TFileSelectionFrame.ListBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=13) and (Shift=[]) then CanOpen:=true;
end;

procedure TFileSelectionFrame.ListBoxKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=13) and (Shift=[]) and CanOpen then
    begin
      CanOpen:=false;
      if MessageBox(0,PChar(DCOP.RunEnvironment+'\'+utf8towincp((Sender as TListBox).GetSelectedText)),PChar(utf8towincp('是否打开文件？')),MB_OKCANCEL)=IDOK
        then begin
          //WinExec(PChar('cmd.exe /c call '+DCOP.RunEnvironment+'\'+utf8towincp((Sender as TListBox).GetSelectedText)),SW_SHOW);
          ShellExecute(0,'open',PChar(DCOP.RunEnvironment+'\'+utf8towincp((Sender as TListBox).GetSelectedText)),nil,nil,SW_SHOW);
        end;

    end;
end;



procedure TFileSelectionFrame.Add(str:string);
begin
  Self.ListBox.AddItem(str,nil);
end;
procedure TFileSelectionFrame.Clear;
begin
  Self.ListBox.Clear;
end;
procedure TFileSelectionFrame.Sort;
begin
  Self.ListBox.Sorted:=true;
end;

end.

