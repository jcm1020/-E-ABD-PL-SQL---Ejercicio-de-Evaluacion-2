
-- ToDo: Preparar para excepción AUTOCAR_COMPLETO

drop table modelos cascade constraints;
drop table autocares cascade constraints;
drop table recorridos cascade constraints;
drop table viajes cascade constraints;
drop table tickets cascade constraints;

create table modelos(
 idModelo integer primary key,
 nplazas integer
);

create table autocares(
  idAutocar   integer primary key,
  modelo      integer references modelos,
  kms         integer not null
);

create table recorridos(
   idRecorrido      integer primary key,
   estacionOrigen   varchar(15) not null,
   estacionDestino  varchar(15) not null,
   kms              numeric(6,2) not null,
   precio           numeric(5,2) not null
);

create table viajes(
 idViaje     	integer primary key,
 idAutocar   	integer references autocares  not null,
 idRecorrido 	integer references recorridos not null,
 fecha 		    date not null,
 nPlazasLibres	integer not null,
 Conductor    varchar(25) not null,
 unique (idRecorrido, fecha) 
);

drop sequence seq_viajes;
create sequence seq_viajes;

create table tickets(
 idTicket 	integer primary key,
 idViaje  	integer references viajes not null,
 fechaCompra    date not null,
 cantidad       integer not null,
 precio		numeric(5,2) not null
);
drop sequence seq_tickets;
create sequence seq_tickets;

insert into modelos (idModelo, nPlazas) values ( 1, 40 );  
insert into modelos (idModelo, nPlazas) values ( 2, 15 );  
insert into modelos (idModelo, nPlazas) values ( 3, 35 );  

insert into autocares ( idAutocar, modelo, kms) values (1, 1, 1000);
insert into autocares ( idAutocar, modelo, kms) values (2, 1, 7500);
insert into autocares ( idAutocar, modelo, kms) values (3, 2, 2000);
insert into autocares ( idAutocar, kms) values (4, 1000);

insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (1, 'Burgos', 'Madrid', 201, 10 );
insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (2, 'Burgos', 'Madrid', 200, 12);
insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (3, 'Madrid', 'Burgos', 200, 10);
insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (4, 'Leon', 'Zamora', 150, 6);

insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values (seq_viajes.nextval, 1, 1, DATE '2009-1-22', 30, 'Juan');
insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values (seq_viajes.nextval, 1, 1, trunc(current_date)+1, 38, 'Javier');
insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values (seq_viajes.nextval, 1, 1, trunc(current_date)+7, 10, 'Maria');
insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values(seq_viajes.nextval, 2, 4, trunc(current_date)+7, 40, 'Ana');


commit;
--exit;


create or replace procedure crearViaje( m_idRecorrido int, m_idAutocar int, m_fecha date, m_conductor varchar) is

    RECORRIDO_INEXISTENTE exception;
    PRAGMA EXCEPTION_INIT( RECORRIDO_INEXISTENTE, -20001);
    
    AUTOCAR_INEXISTENTE exception;
    PRAGMA EXCEPTION_INIT( AUTOCAR_INEXISTENTE, -20002);
    
    AUTOCAR_OCUPADO exception;
    PRAGMA EXCEPTION_INIT( AUTOCAR_OCUPADO, -20003);
    
    VIAJE_DUPLICADO exception;
    PRAGMA EXCEPTION_INIT( VIAJE_DUPLICADO, -20004);
    
    v_recorrido  recorridos%ROWTYPE;
    num_recorridos  integer;
    num_autocares integer;
    num_viajes integer;
    num_plazas integer;
    plazas integer:=25;
    v_idviaje integer;
    constraint varchar(200);
begin
    --Control de excepcion de recorrido inexistente
    SELECT COUNT(*) INTO num_recorridos FROM recorridos WHERE idrecorrido = m_idRecorrido;
    IF num_recorridos <=0 THEN
        raise_application_error(-20001, 'Recorrido inexistente.');
    ELSE
        SELECT COUNT(*) INTO num_autocares FROM autocares WHERE idautocar = m_idAutocar;
        IF num_autocares <=0 THEN
            raise_application_error(-20002, 'Autocar inexistente.');
        END IF;
    END IF;
    
    --Control de excepcion viaje duplicado
    SELECT COUNT(*) INTO num_viajes FROM viajes WHERE idautocar = m_idAutocar AND idrecorrido = m_idRecorrido AND TRUNC(fecha) = TRUNC(m_fecha);
            --SELECT COUNT(*) INTO num_viajes FROM viajes WHERE idautocar = m_idAutocar AND idrecorrido = m_idRecorrido;
    IF num_viajes > 0 THEN
                raise_application_error(-20004, 'Viaje duplicado.');
    END IF;
    
    --Control de excepcion autocar ocupado
    SELECT COUNT(*) INTO num_autocares FROM viajes WHERE  idautocar = m_idAutocar AND TRUNC(fecha) = TRUNC(m_fecha);
    IF num_autocares > 0 THEN
        raise_application_error(-20003, 'Autocar ocupado.');
    END IF;
    
    --Pasados los controles anteriores podemos realizar la insercion
    
    begin
        begin
            SELECT b.nplazas INTO num_plazas FROM autocares A 
            JOIN modelos B ON A.modelo=B.idmodelo            
            WHERE A.idautocar=m_idAutocar;
            IF sql%rowcount is not null THEN
                plazas:=num_plazas;
            END IF;
        exception
            when NO_DATA_FOUND then
                    --dbms_output.put_line('No se encontraron datos en SELECT');
                    --raise_application_error(-20005, 'Modelo inexistente.');
                    plazas:=25;
        end;  
        SELECT  MAX(idviaje) INTO v_idviaje FROM viajes;
        INSERT INTO viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor) 
        VALUES (v_idviaje+1, m_idAutocar, m_idRecorrido, m_fecha, plazas, m_conductor);
        commit;
    exception
        when OTHERS then
            --dbms_output.put_line('Otro error no controlado realizando la insercion');
            raise_application_error(-20004, 'Viaje duplicado.');
        
    end;
    
    --Mas informacion sobre un error unique constraint que se produjo haciendo la practica
    /*SELECT DISTINCT table_name INTO constraint FROM all_indexes
    WHERE index_name = 'unique constraint (C0015500) violated' ;
    dbms_output.put_line(constraint);*/
    
    
    
end;
/

set serveroutput on


create or replace procedure test_crearViaje is
begin
  
  --Caso 1: RECORRIDO_INEXISTENTE
  begin
    crearViaje(11, 2, trunc(current_date), 'Juanito');
    dbms_output.put_line('Mal no detecta RECORRIDO_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20001 then
        dbms_output.put_line('OK: Detecta RECORRIDO_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta RECORRIDO_INEXISTENTE: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 2: AUTOCAR_INEXISTENTE
   begin
    crearViaje(1, 22, trunc(current_date), 'Juanito');
    dbms_output.put_line('Mal no detecta AUTOCAR_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20002 then
        dbms_output.put_line('OK: Detecta AUTOCAR_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta AUTOCAR_INEXISTENTE: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 3: AUTOCAR_OCUPADO
   begin
    crearViaje(2, 1, trunc(current_date)+1, 'Juanito');
    dbms_output.put_line('Mal no detecta AUTOCAR_OCUPADO');
  exception
    when others then
      if sqlcode = -20003 then
        dbms_output.put_line('OK: Detecta AUTOCAR_OCUPADO: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta AUTOCAR_OCUPADO: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 4: VIAJE_DUPLICADO
   begin
    crearViaje(1, 2, trunc(current_date)+1, 'Juanito');
    dbms_output.put_line('Mal no detecta VIAJE_DUPLICADO');
  exception
    when others then
      if sqlcode = -20004 then
        dbms_output.put_line('OK: Detecta VIAJE_DUPLICADO: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta VIAJE_DUPLICADO: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 4: Crea un viaje OK
  begin
    crearViaje(1, 1, trunc(current_date)+3, 'Pedrito');
    dbms_output.put_line('Parece OK Crea un viaje válido');
  exception
    when others then
        dbms_output.put_line('MAL Crea un viaje válido: '||sqlerrm);
  end;
  
  
  --Caso 5: Crea un viaje OK con autcar sin modelo
  begin
    crearViaje(1, 4, trunc(current_date)+4, 'Jorgito');
    dbms_output.put_line('Parece OK Crea un viaje válido sin modelo');
  exception
    when others then
        dbms_output.put_line('MAL Crea un viaje válido sin modelo: '||sqlerrm);
  end;
  
  
  --Caso FINAL: Todo OK
  declare
    varContenidoReal varchar(500);
    varContenidoEsperado    varchar(500):= 
      '11122/01/0930Juan#211' || to_char(trunc(current_date)+1,'DD/MM/YY') || '38Javier#311' || to_char(trunc(current_date)+7,'DD/MM/YY') || '10Maria#424' || to_char(trunc(current_date)+7,'DD/MM/YY') || '40Ana#511' || to_char(trunc(current_date)+3,'DD/MM/YY') || '40Pedrito#641' || to_char(trunc(current_date)+4,'DD/MM/YY') || '25Jorgito';
    
  begin
    rollback; --por si se olvida commit de matricular
    
    SELECT listagg( idViaje || idAutocar || idRecorrido || fecha || nPlazasLibres || Conductor, '#')
        within group (order by idViaje)
    into varContenidoReal
    FROM viajes;
    
    if varContenidoReal=varContenidoEsperado then
      dbms_output.put_line('OK: Sí que modifica bien la BD.'); 
    else
      dbms_output.put_line('Mal no modifica bien la BD.'); 
      dbms_output.put_line('Contenido real:     '||varContenidoReal); 
      dbms_output.put_line('Contenido esperado: '||varContenidoEsperado); 
    end if;
    
  exception
    when others then
      dbms_output.put_line('Mal caso todo OK: '||sqlerrm);
  end;
  
end;
/

begin
  test_crearViaje;
end;
/

