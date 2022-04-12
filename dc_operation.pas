//{$define CheckMode}
unit DC_Operation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LazUTF8, Windows, RegExpr;

const
  MaxRunParameterCount = 7;

type
  Tfilename = string;
  Taddrname = string;
  Textname  = string;
  TNumberialMode = (nmDec=0, nmHex=1);

  TDC_Operation = class
    FRunEnvironment:Taddrname;
  protected
    procedure SetRunEnvironment(path:Taddrname);
  public
    property RunEnvironment:Taddrname read FRunEnvironment write SetRunEnvironment;
  public
    function EnvBackDir:boolean;//改路径为其上一级，若失败返回false
    function EnvIntoDir(folder:Taddrname):boolean;//改路径为其中一个子目录，若失败返回false
  end;

var

  DCOP:TDC_Operation;
  RegExp:TRegExpr;
  RunParameters:array[0..MaxRunParameterCount]of ansistring;
  RunEnumCount:byte;

  function Numberize(num:longint;mode:TNumberialMode):string;
  function ClipStr(st,en,ori:string):string;//删除ori中从第一个st片段到第一个en片段的内容（包括头尾）

  function Environmentalization(pathname,env:Taddrname):Taddrname;
  procedure PathToAFX(const ori:Taddrname;var adr,fil,ext:Taddrname);

  //环境变量，之后的函数都在环境变量之下
  function BackDir(var path:Taddrname):boolean;//改路径为其上一级，若失败返回false
  function IntoDir(var path:Taddrname;folder:Taddrname):boolean;//改路径为其中一个子目录，若失败返回false


  //基础移动
  function FileMoveTo(ori,dest:Taddrname):boolean;
  function FileCopyTo(ori,dest:Taddrname):boolean;
  function FileReName(ori,dest:Taddrname):boolean;




  //具体功能
  procedure FlattenDirAllExt(addr:Taddrname);
  procedure FlattenDir(addr:Taddrname;ext:Textname);

  procedure HierarchyDir(addr:Taddrname);

  procedure ChangeNameFolder(addr:Taddrname;oriStr,destStr:string);
  procedure ChangeNameSelect(addr:Taddrname;oriStr,destStr:string);
  procedure InsertNameLFolder(addr:Taddrname;cStr:string);
  procedure InsertNameLSelect(addr:Taddrname;cStr:string);
  procedure InsertNameRFolder(addr:Taddrname;cStr:string);
  procedure InsertNameRSelect(addr:Taddrname;cStr:string);
  procedure ClipNameFolder(addr:Taddrname;cSt,cEn:string);
  procedure ClipNameSelect(addr:Taddrname;cSt,cEn:string);


  procedure RegExprNameFolder(addr:Taddrname;oriStr,destStr:string);
  procedure RegExprNameSelect(addr:Taddrname;oriStr,destStr:string);


  procedure RegExpSelectFolder(addr:Taddrname;reg:string);
  procedure RegExpSelectDir(addr:Taddrname;reg:string);


implementation
uses Apiglio_Useful, main_directorycommander;

procedure ShowFileMessage(str:string);//显示消息
begin
  Form_DirectoryCommander.Frame_AufScript1.Auf.Script.writeln(str);
end;

function Numberize(num:longint;mode:TNumberialMode):string;
begin
  result:='';
  //ShowFileMessage(inttostr(num));
  case mode of
    nmDec:
      begin
        result:=IntToStr(num);
        while length(result)<10 do result:='0'+result;
      end;
    nmHex:
      begin
        result:=IntToHex(num,8);
      end;
    else result:='NSN_';
  end;
end;
function ClipStr(st,en,ori:string):string;
var p_st,p_en,l_st,l_en:integer;
begin
  result:=ori;
  p_st:=pos(st,ori);
  p_en:=pos(en,ori);
  l_st:=length(st);
  l_en:=length(en);
  if (p_st<=0) or (p_en<=0) or (p_st+l_st-1>=p_en) then exit;
  delete(result,p_st+l_st,p_en-p_st-l_st);
end;

function Environmentalization(pathname,env:Taddrname):Taddrname;//根据RunEnvironment截断完整路径文件名
begin
  if (env='') then begin result:='';exit end;
  if (pathname='') then begin result:='';exit end;
  if length(pathname)<length(env) then begin result:='';exit end;
  while env[1]=pathname[1] do
    begin
      delete(env,1,1);
      delete(pathname,1,1);
      if length(env)=0 then break;
    end;
  if (env<>'')or(pathname='') then result:=''
  else begin
    while pathname[1] in ['/','\'] do
      begin
        delete(pathname,1,1);
        if length(pathname)=0 then break;
      end;
    result:=pathname;
  end;
end;
function ConvertToFlattenedName(pathname:Taddrname):Taddrname;//转化为扁平化文件名
var pi:integer;
begin
  result:=pathname;
  for pi:=1 to length(pathname) do if result[pi]='\' then result[pi]:='$';
end;
function ConvertToHierarchyName(pathname:Taddrname):Taddrname;//转化为层次化文件名
var pi:integer;
begin
  result:=pathname;
  for pi:=1 to length(pathname) do if result[pi]='$' then result[pi]:='\';
end;

procedure PathToAFX(const ori:Taddrname;var adr,fil,ext:Taddrname);
var oriname,stmp:Taddrname;
    len,tmp:longint;
begin
  oriname:=ori;
  adr:='';
  while true do begin
    tmp:=pos('\',oriname);
    len:=length(oriname);
    if tmp > 0 then begin
      stmp:=oriname;
      delete(oriname,1,tmp);
      delete(stmp,tmp,len);
      adr:=adr+'\'+stmp;
    end else begin
      break;
    end;
  end;
  delete(adr,1,1);
  tmp:=pos('.',oriname);
  len:=length(oriname);
  if tmp>0 then begin
    ext:=oriname;
    delete(ext,1,tmp);
    delete(oriname,tmp,len);
  end else begin
    ext:='';
  end;
  fil:=oriname;
end;



function BackDir(var path:Taddrname):boolean;
var tmp:Taddrname;
begin
  tmp:=path;
  StringReplace(tmp,'/','\',[rfReplaceAll]);
  while tmp[length(tmp)] = '\' do delete(tmp,length(tmp),1);
  if pos('\',tmp)<=0 then begin
    result:=false;
    exit;
  end;
  while tmp[length(tmp)]<>'\' do delete(tmp,length(tmp),1);
  path:=tmp;
  result:=true;
end;

function IntoDir(var path:Taddrname;folder:Taddrname):boolean;
var tmp:Taddrname;
begin
  tmp:=path;
  if not (tmp[length(tmp)] in ['\','/']) then tmp:=tmp+'\';
  tmp:=tmp+folder;
  if not DirectoryExists(tmp) then begin
    result:=false;
    exit;
  end;
  path:=tmp;
  result:=true;
end;

function FileMoveTo(ori,dest:Taddrname):boolean;
var ofile,dfile:string;
begin
  ofile:=DCOP.RunEnvironment+'\'+ori;
  dfile:=DCOP.RunEnvironment+'\'+dest;
  {$ifndef CheckMode}
    if ForceDirectories(wincptoutf8(ExtractFilePath(dfile))) then ;
    result:=MoveFile(PChar(ofile),PChar(dfile));
  {$else}
    ShowFileMessage('M:'+wincptoutf8(ofile)+'-'+wincptoutf8(dfile));
  {$endif}
end;

function FileCopyTo(ori,dest:Taddrname):boolean;
var ofile,dfile:string;
begin
  ofile:=DCOP.RunEnvironment+'\'+ori;
  dfile:=DCOP.RunEnvironment+'\'+dest;
  {$ifndef CheckMode}
    if ForceDirectories(wincptoutf8(ExtractFilePath(dfile))) then ;
    result:=CopyFile(PChar(ofile),PChar(dfile),false);
  {$else}
    ShowFileMessage('C:'+wincptoutf8(ofile)+'-'+wincptoutf8(dfile));
  {$endif}
end;

function FileReName(ori,dest:Taddrname):boolean;
var ofile,dfile:string;
begin
  ofile:=DCOP.RunEnvironment+'\'+ori;
  dfile:=DCOP.RunEnvironment+'\'+dest;
  {$ifndef CheckMode}
    ReNameFile(wincptoutf8(ofile),wincptoutf8(dfile));
    result:=true;
  {$else}
    ShowFileMessage('R:'+wincptoutf8(ofile)+'-'+wincptoutf8(dfile));
  {$endif}
end;





procedure enum_flatten(filename:string);
var newname:Taddrname;
begin
  newname:=Environmentalization(filename,DCOP.RunEnvironment);
  newname:=ConvertToFlattenedName(newname);
  filename:=Environmentalization(filename,DCOP.RunEnvironment);
  FileMoveTo(filename,newname);
end;

procedure FlattenDirAllExt(addr:Taddrname);

begin
  Usf.each_file(DCOP.RunEnvironment+'\'+addr,@enum_flatten);
end;

procedure FlattenDir(addr:Taddrname;ext:Textname);
begin
  if ext='' then FlattenDirAllExt(addr) else
    begin
      //
    end;
end;

procedure enum_Hierarchy(filename:string);
var newname:Taddrname;
begin
  newname:=Environmentalization(filename,DCOP.RunEnvironment);
  newname:=ConvertToHierarchyName(newname);
  filename:=Environmentalization(filename,DCOP.RunEnvironment);
  FileMoveTo(filename,newname);
end;

procedure HierarchyDir(addr:Taddrname);

begin
  Usf.each_file(DCOP.RunEnvironment+'\'+addr,@enum_hierarchy);
end;


procedure enum_RegExprName(filename:string);
//RunParameters[0]: 需替换部分
//RunParameters[1]: 替换后内容
var newname,stmp:Taddrname;
begin
  newname:=Environmentalization(filename,DCOP.RunEnvironment);
  filename:=newname;
  RegExp.Expression:=RunParameters[0];
  newname:=RegExp.Replace(newname,RunParameters[1],true);
  FileReName(filename,newname);
end;

procedure enum_ChangeName(filename:string);
//RunParameters[0]: 需替换部分
//RunParameters[1]: 替换后内容
//RunParameters[4]: 序数替换
var newname,stmp:Taddrname;
begin
  newname:=Environmentalization(filename,DCOP.RunEnvironment);
  //ShowFileMessage(RunParameters[4]);
  stmp:=StringReplace(RunParameters[1],'~n',RunParameters[4],[rfReplaceAll]);
  //ShowFileMessage(stmp);
  newname:=StringReplace(newname,RunParameters[0],stmp,[rfReplaceAll]);
  filename:=Environmentalization(filename,DCOP.RunEnvironment);
  FileReName(filename,newname);
end;
procedure enum_InsertNameL(filename:string);
//RunParameters[0]: 增加部分
//RunParameters[4]: 序数替换
var newname,stmp:Taddrname;
    adr,fil,ext:Taddrname;
    tmp,len:integer;
begin
  newname:=Environmentalization(filename,DCOP.RunEnvironment);
  //ShowFileMessage(RunParameters[4]);
  stmp:=StringReplace(RunParameters[0],'~n',RunParameters[4],[rfReplaceAll]);
  PathToAFX(newname,adr,fil,ext);
  newname:='';
  if adr<>'' then newname:=newname+'\'+adr+'\';
  newname:=newname+stmp+fil;
  if ext<>'' then newname:=newname+'.'+ext;
  filename:=Environmentalization(filename,DCOP.RunEnvironment);
  FileReName(filename,newname);
end;
procedure enum_InsertNameR(filename:string);
//RunParameters[0]: 增加部分
//RunParameters[4]: 序数替换
var newname,stmp:Taddrname;
    adr,fil,ext:Taddrname;
    tmp,len:integer;
begin
  newname:=Environmentalization(filename,DCOP.RunEnvironment);
  //ShowFileMessage(RunParameters[4]);
  stmp:=StringReplace(RunParameters[0],'~n',RunParameters[4],[rfReplaceAll]);
  PathToAFX(newname,adr,fil,ext);
  newname:='';
  if adr<>'' then newname:=newname+'\'+adr+'\';
  newname:=newname+fil+stmp;
  if ext<>'' then newname:=newname+'.'+ext;
  filename:=Environmentalization(filename,DCOP.RunEnvironment);
  FileReName(filename,newname);
end;

procedure enum_ClipName(filename:string);
//RunParameters[0]: 开头片段
//RunParameters[1]: 结尾片段
var newname,adr,fil,ext:Taddrname;
begin
  PathToAFX(filename,adr,fil,ext);
  adr:=fil;
  if ext<>'' then adr:=adr+'.'+ext;
  newname:=ClipStr(RunParameters[0],RunParameters[1],adr);
  filename:=Environmentalization(filename,DCOP.RunEnvironment);
  FileReName(filename,newname);
end;

procedure RegExprNameFolder(addr:Taddrname;oriStr,destStr:string);
begin
  if oriStr='' then exit;
  RunParameters[0]:=oriStr;
  RunParameters[1]:=destStr;
  Usf.each_file_in_folder(DCOP.RunEnvironment+'\'+addr,@enum_RegExprName);
end;

procedure RegExprNameSelect(addr:Taddrname;oriStr,destStr:string);
var tmp:longint;
    items:TStrings;
begin
  if oriStr='' then exit;
  RunParameters[0]:=oriStr;
  RunParameters[1]:=destStr;
  tmp:=0;
  items:=Form_DirectoryCommander.FileSelectionFrame1.ListBox.Items;
  while tmp<items.Count do
    begin
      RunParameters[4]:=Numberize(tmp,nmDec);
      //filemessage(RunParameters[4]);
      enum_RegExprName(DCOP.RunEnvironment+'\'+addr+'\'+utf8towincp(items[tmp]));
      inc(tmp);
    end;
end;

procedure ChangeNameFolder(addr:Taddrname;oriStr,destStr:string);
begin
  if oriStr='' then exit;
  RunParameters[0]:=oriStr;
  RunParameters[1]:=destStr;
  Usf.each_file_in_folder(DCOP.RunEnvironment+'\'+addr,@enum_ChangeName);
end;

procedure ChangeNameSelect(addr:Taddrname;oriStr,destStr:string);
var tmp:longint;
    items:TStrings;
begin
  if oriStr='' then exit;
  RunParameters[0]:=oriStr;
  RunParameters[1]:=destStr;
  tmp:=0;
  items:=Form_DirectoryCommander.FileSelectionFrame1.ListBox.Items;
  while tmp<items.Count do
    begin
      RunParameters[4]:=Numberize(tmp,nmDec);
      //filemessage(RunParameters[4]);
      enum_ChangeName(DCOP.RunEnvironment+'\'+addr+'\'+utf8towincp(items[tmp]));
      inc(tmp);
    end;
end;

procedure InsertNameLFolder(addr:Taddrname;cStr:string);
begin
  RunParameters[0]:=cStr;
  Usf.each_file_in_folder(DCOP.RunEnvironment+'\'+addr,@enum_InsertNameL);
end;

procedure InsertNameLSelect(addr:Taddrname;cStr:string);
var tmp:longint;
    items:TStrings;
begin
  RunParameters[0]:=cStr;
  tmp:=0;
  items:=Form_DirectoryCommander.FileSelectionFrame1.ListBox.Items;
  while tmp<items.Count do
    begin
      RunParameters[4]:=Numberize(tmp,nmDec);
      //showfilemessage(RunParameters[4]);
      enum_InsertNameL(DCOP.RunEnvironment+'\'+addr+'\'+utf8towincp(items[tmp]));
      inc(tmp);
    end;
end;
procedure InsertNameRFolder(addr:Taddrname;cStr:string);
begin
  RunParameters[0]:=cStr;
  Usf.each_file_in_folder(DCOP.RunEnvironment+'\'+addr,@enum_InsertNameR);
end;

procedure InsertNameRSelect(addr:Taddrname;cStr:string);
var tmp:longint;
    items:TStrings;
begin
  RunParameters[0]:=cStr;
  tmp:=0;
  items:=Form_DirectoryCommander.FileSelectionFrame1.ListBox.Items;
  while tmp<items.Count do
    begin
      RunParameters[4]:=Numberize(tmp,nmDec);
      //showfilemessage(RunParameters[4]);
      enum_InsertNameR(DCOP.RunEnvironment+'\'+addr+'\'+utf8towincp(items[tmp]));
      inc(tmp);
    end;
end;

procedure ClipNameFolder(addr:Taddrname;cSt,cEn:string);
begin
  RunParameters[0]:=cSt;
  RunParameters[1]:=cEn;
  Usf.each_file_in_folder(DCOP.RunEnvironment+'\'+addr,@enum_ClipName);
end;

procedure ClipNameSelect(addr:Taddrname;cSt,cEn:string);
var tmp:longint;
    items:TStrings;
begin
  RunParameters[0]:=cSt;
  RunParameters[1]:=cEn;
  tmp:=0;
  items:=Form_DirectoryCommander.FileSelectionFrame1.ListBox.Items;
  while tmp<items.Count do
    begin
      enum_ClipName(DCOP.RunEnvironment+'\'+addr+'\'+utf8towincp(items[tmp]));
      inc(tmp);
    end;
end;

procedure enum_RegSelect(filename:string);
begin
  filename:=Environmentalization(filename,DCOP.RunEnvironment);
  if RegExp.Exec(filename) then Form_DirectoryCommander.FileSelectionFrame1.Add(wincptoutf8(filename));
end;

procedure RegExpSelectFolder(addr:Taddrname;reg:string);
begin
  Form_DirectoryCommander.FileSelectionFrame1.Clear;
  RegExp.Expression:=reg;
  Usf.each_file_in_folder(DCOP.RunEnvironment+'\'+addr,@enum_RegSelect);
end;

procedure RegExpSelectDir(addr:Taddrname;reg:string);
begin
  Form_DirectoryCommander.FileSelectionFrame1.Clear;
  RegExp.Expression:=reg;
  Usf.each_file(DCOP.RunEnvironment+'\'+addr,@enum_RegSelect);
end;


procedure TDC_Operation.SetRunEnvironment(path:Taddrname);
begin
  Self.FRunEnvironment:=path;
  GlobalExpressionList.TryAddExp('env',narg('"',wincptoutf8(path),'"'));
end;
function TDC_Operation.EnvBackDir:boolean;
begin
  result:=BackDir(Self.FRunEnvironment);
end;
function TDC_Operation.EnvIntoDir(folder:Taddrname):boolean;
begin
  result:=IntoDir(Self.FRunEnvironment,folder);
end;



initialization
  DCOP:=TDC_Operation.Create;
  DCOP.RunEnvironment:= GetCurrentDir;
  for RunEnumCount:=0 to MaxRunParameterCount do RunParameters[RunEnumCount]:='';
  RegExp:=TRegExpr.Create;

finalization
  RegExp.Free;
  DCOP.Free;

end.

