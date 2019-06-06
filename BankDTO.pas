unit BankDTO;

interface

uses
  System.SysUtils, Classes, DTO,
  Generics.Collections,
  Atributos;

type
  TBankDTO = class(TDTO)
  private
    FPK: Integer;
    FCODE: string;
    FNAME: string;
    FURL: string;
    FDeltaList: TDictionary<String, String>;
  public
  published

    [TPK('ID', [ldGrid, ldLookup, ldComboBox])]
    property PK: Integer  read FPK write FPK;
    [TColumn('CODE', 'Code', 80, [ldGrid, ldLookup, ldCombobox], False)]
    property Code: string read FCODE write FCODE;
    [TColumn('NAME', 'Name', 450, [ldGrid, ldLookup, ldCombobox], False)]
    property Name: string read FNAME write FNAME;
    [TColumn('URL', 'Url', 450, [ldGrid, ldLookup, ldCombobox], False)]
    property Url: string read FURL write FURL;
  end;

implementation

{ TBankDTO }

end.
