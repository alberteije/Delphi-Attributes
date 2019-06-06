unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Datasnap.DBClient, DTO, RTTI, Atributos, BankDTO, Vcl.StdCtrls, Generics.Collections;

type
  TForm1 = class(TForm)
    ClientDataSet1: TClientDataSet;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    procedure FormCreate(Sender: TObject);

    procedure SettingCDSFromDTO(pCDS: TClientDataSet; pDTOClass: TClassDTO);
    procedure SettingGridFromDTO(pGrid: TDBGrid; pDTOClass: TClassDTO);
    procedure UpdateCaptionGrid(pGrid: TDBGrid; pFieldName, pCaption: string);
    procedure SettingTamanhoColunaGrid(pGrid: TDBGrid; pFieldName: string; pTamanho: integer; pCaption: String);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
var
  Bank: TBankDTO;
  BankList: TObjectList<TBankDTO>;
  I: Integer;
begin
  SettingCDSFromDTO(ClientDataSet1, TBankDTO);
  SettingGridFromDTO(DBGrid1, TBankDTO);

  BankList := TObjectList<TBankDTO>.Create;

  Bank := TBankDTO.Create;
  Bank.Code := '001';
  Bank.Name := 'AMERICAN BANK';
  Bank.Url := 'www.americanbank.com';
  BankList.Add(Bank);

  Bank := TBankDTO.Create;
  Bank.Code := '002';
  Bank.Name := 'AFRICAN BANK';
  Bank.Url := 'www.africannbank.com';
  BankList.Add(Bank);

  for I := 0 to BankList.Count - 1 do
  begin
    ClientDataSet1.Append;
    ClientDataSet1.FieldByName('CODE').AsString := TBankDTO(BankList.Items[I]).Code;
    ClientDataSet1.FieldByName('NAME').AsString := TBankDTO(BankList.Items[I]).Name;
    ClientDataSet1.FieldByName('URL').AsString := TBankDTO(BankList.Items[I]).Url;
    ClientDataSet1.Post;
  end;

end;














////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


procedure TForm1.SettingCDSFromDTO(pCDS: TClientDataSet; pDTOClass: TClassDTO);
var
  Contexto: TRttiContext;
  Tipo: TRttiType;
  Propriedade: TRttiProperty;
  Atributo: TCustomAttribute;
  NomeTipo, NomeCampo: string;

  function LengthAtributo(pColumn: Atributos.TColumn): integer; overload;
  begin
    if pColumn.Length > 0 then
      Result := pColumn.Length
    else
      Result := 50;
  end;

  function LengthAtributo(pColumn: Atributos.TColumnDisplay): integer; overload;
  begin
    if pColumn.Length > 0 then
      Result := pColumn.Length
    else
      Result := 50;
  end;

begin
  try
    Contexto := TRttiContext.Create;
    Tipo := Contexto.GetType(pDTOClass);

    // Configura ClientDataset
    pCDS.Close;
    pCDS.FieldDefs.Clear;
    pCDS.IndexDefs.Clear;

    // Preenche os nomes dos campos do CDS
    for Propriedade in Tipo.GetProperties do
    begin
      for Atributo in Propriedade.GetAttributes do
      begin
        if Atributo is TId then
        begin
          pCDS.FieldDefs.add('ID', ftInteger);
        end

        else if Atributo is Atributos.TColumn then
        begin
          NomeCampo := (Atributo as Atributos.TColumn).Name;
          if Propriedade.PropertyType.TypeKind in [tkString, tkUString, tkAnsiString] then
          begin
            pCDS.FieldDefs.add((Atributo as Atributos.TColumn).Name, ftString, LengthAtributo(Atributo as Atributos.TColumn));
          end
          else if Propriedade.PropertyType.TypeKind in [tkFloat] then
          begin
            NomeTipo := LowerCase(Propriedade.PropertyType.Name);
            if NomeTipo = 'tdatetime' then
              pCDS.FieldDefs.add((Atributo as Atributos.TColumn).Name, ftDateTime)
            else
              pCDS.FieldDefs.add((Atributo as Atributos.TColumn).Name, ftFloat);
          end
          else if Propriedade.PropertyType.TypeKind in [tkInt64, tkInteger] then
          begin
            pCDS.FieldDefs.add((Atributo as Atributos.TColumn).Name, ftInteger);
          end
          else if Propriedade.PropertyType.TypeKind in [tkEnumeration] then
          begin
            pCDS.FieldDefs.add((Atributo as TColumn).Name, ftBoolean);
          end;
        end;

      end;
    end;
    pCDS.CreateDataSet;

    for Propriedade in Tipo.GetProperties do
    begin
      for Atributo in Propriedade.GetAttributes do
      begin

        if Atributo is TColumn then
          NomeTipo := (Atributo as TColumn).Name;
        if Atributo is TId then
          NomeTipo := (Atributo as TId).NameField;

        if Atributo is TFormatter then
        begin
          // Máscaras
          if Propriedade.PropertyType.TypeKind in [tkInt64, tkInteger] then
            TNumericField(pCDS.FieldByName(NomeTipo)).DisplayFormat := (Atributo as Atributos.TFormatter).Formatter;
          if Propriedade.PropertyType.TypeKind in [tkFloat] then
            TNumericField(pCDS.FieldByName(NomeTipo)).DisplayFormat := (Atributo as Atributos.TFormatter).Formatter;
          if Propriedade.PropertyType.TypeKind in [tkString, tkUString, tkAnsiString] then
            TStringField(pCDS.FieldByName(NomeTipo)).EditMask := (Atributo as Atributos.TFormatter).Formatter;
          // Alinhamento
          TStringField(pCDS.FieldByName(NomeTipo)).Alignment := (Atributo as TFormatter).Alignment;
        end;
      end;
    end;

  finally
    Contexto.Free;
  end;
end;

procedure TForm1.SettingGridFromDTO(pGrid: TDBGrid; pDTOClass: TClassDTO);
var
  Contexto: TRttiContext;
  Tipo: TRttiType;
  Propriedade: TRttiProperty;
  Atributo: TCustomAttribute;
begin
  try
    Contexto := TRttiContext.Create;
    Tipo := Contexto.GetType(pDTOClass);

    // Configura a Grid
    for Propriedade in Tipo.GetProperties do
    begin
      for Atributo in Propriedade.GetAttributes do
      begin

        if Atributo is TId then
        begin
          if (Atributo as TId).LocalDisplayContainsOneTheseItems([ldGrid, ldLookup]) then
          begin
            UpdateCaptionGrid(pGrid, (Atributo as TId).NameField, 'ID');
          end
          else
          begin
            SettingTamanhoColunaGrid(pGrid, (Atributo as TId).NameField, -1, 'ID');
          end;
        end

        else if Atributo is TColumn then
        begin
          if (Atributo as TColumn).LocalDisplayContainsOneTheseItems([ldGrid, ldLookup]) then
          begin
            UpdateCaptionGrid(pGrid, (Atributo as TColumn).Name, (Atributo as TColumn).Caption);

            if (Atributo as TColumn).Length > 0 then
            begin
              SettingTamanhoColunaGrid(pGrid, (Atributo as TColumn).Name, (Atributo as TColumn).Length, (Atributo as TColumn).Caption);
            end;
          end
          else
          begin
            SettingTamanhoColunaGrid(pGrid, (Atributo as TColumn).Name, -1, (Atributo as TColumn).Caption);
          end;
        end;

      end;
    end;
  finally
    Contexto.Free;
  end;
end;


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

procedure TForm1.UpdateCaptionGrid(pGrid: TDBGrid; pFieldName, pCaption: string);
var
  i: integer;
begin
  for i := 0 to pGrid.Columns.Count - 1 do
  begin
    if pGrid.Columns[i].FieldName = pFieldName then
    begin
      pGrid.Columns[i].Title.Caption := pCaption;
      pGrid.Columns[i].Title.Alignment := taCenter;
      pGrid.Columns[i].Title.Font.Color := clBlue;
      Break;
    end;
  end;
end;

procedure TForm1.SettingTamanhoColunaGrid(pGrid: TDBGrid; pFieldName: string; pTamanho: integer; pCaption: String);
var
  i: integer;
begin
  for i := 0 to pGrid.Columns.Count - 1 do
  begin
    if pGrid.Columns[i].FieldName = pFieldName then
    begin
      if pTamanho <= 0 then
      begin
        pGrid.Columns[i].Visible := False;
      end
      else
      begin
        if pTamanho < (Length(pCaption) * 8) then
          pTamanho := (Length(pCaption) * 6);
        pGrid.Columns[i].Visible := True;
        pGrid.Columns[i].Width := pTamanho;
      end;
      Break;
    end;
  end;
end;
end.
