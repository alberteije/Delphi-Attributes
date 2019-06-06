unit DTO;

interface

uses
  DBXJSON, DBXJSONReflect, DBXCommon, RTTI, TypInfo, Atributos, SysUtils,
  Generics.Collections, Classes, System.Json;

type
  TDTO = class(TPersistent)
  public
    constructor Create; overload; virtual;

    function ToJSON: TJSONValue; virtual;
    function ToJSONString: string;

  end;

  TClassDTO = class of TDTO;

  TGenericDTO<T: class> = class
  private
    class function CreateObject: T;
  public
  end;


implementation

{$Region 'TDTO'}
constructor TDTO.Create;
begin
  inherited Create;
end;

function TDTO.ToJSON: TJSONValue;
var
  Serializa: TJSONMarshal;
begin
  Serializa := TJSONMarshal.Create(TJSONConverter.Create);
  try
    Exit(Serializa.Marshal(Self));
  finally
    Serializa.Free;
  end;
end;

function TDTO.ToJSONString: string;
var
  jValue: TJSONValue;
begin
  if Assigned(Self) then
  begin
    jValue := ToJSON;
    try
      Result := jValue.ToString;
    finally
      jValue.Free;
    end;
  end
  else
    Result := '';
end;
{$EndRegion 'TDTO'}

{$Region 'TGenericDTO<T>'}
class function TGenericDTO<T>.CreateObject: T;
var
  Contexto: TRttiContext;
  Tipo: TRttiType;
  Value: TValue;
  Obj: TObject;
begin
  // Criando Objeto via RTTI para chamar o envento OnCreate no Objeto
  Contexto := TRttiContext.Create;
  try
    Tipo := Contexto.GetType(TClass(T));
    Value := Tipo.GetMethod('Create').Invoke(Tipo.AsInstance.MetaclassType, []);
    Result := T(Value.AsObject);
  finally
    Contexto.Free;
  end;
end;
{$EndRegion TGenericDTO<T> }

end.
