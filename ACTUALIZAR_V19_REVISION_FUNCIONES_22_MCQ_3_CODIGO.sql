-- ============================================================
-- V19 DEFINITIVA - REVISIÓN DE CONOCIMIENTOS DE FUNCIONES
-- Programación II · Grupo H
-- 22 selección múltiple = 3.5 puntos
-- 3 construcción de código = 1.5 puntos (revisión docente)
-- ============================================================

-- 1) Permitir guardar respuestas de código y estado pendiente.
alter table public.exam_results
  add column if not exists answers jsonb,
  add column if not exists auto_points numeric(3,2),
  add column if not exists manual_points numeric(3,2) not null default 0,
  add column if not exists manual_pending boolean not null default false;

alter table public.exam_results
  drop constraint if exists exam_results_status_check;

alter table public.exam_results
  add constraint exam_results_status_check
  check (status in ('APROBÓ','PERDIÓ','PENDIENTE REVISIÓN'));

-- 2) Reemplazar el banco anterior por las 25 preguntas aprobadas.
do $$
declare
  v_exam_id bigint;
begin
  select id into v_exam_id
  from public.exams
  where title='Revisión de Conocimientos de Funciones'
    and lower(replace(subject,'ó','o'))='programacion ii'
  order by id
  limit 1;

  if v_exam_id is null then
    insert into public.exams(title,subject,questions)
    values(
      'Revisión de Conocimientos de Funciones',
      'Programación II',
      $json$[{"type": "mcq", "q": "¿Cuál es la función principal de ventas() ?", "o": ["Registrar productos.", "Verificar que existan cajeros antes de iniciar las ventas.", "Buscar clientes.", "Terminar el programa."], "a": 1}, {"type": "mcq", "q": "En def fact(p): , ¿qué representa el parámetro p ?", "o": ["Precio del producto.", "Cantidad de artículos.", "Número de caja.", "Número del cliente."], "a": 2}, {"type": "mcq", "q": "¿Qué hace return(vca,cta) ?", "o": ["Imprime dos valores.", "Guarda dos valores en datos .", "Retorna dos valores a la función que llamó a procfact() .", "Finaliza todo el programa."], "a": 2}, {"type": "mcq", "q": "¿Cuál es la secuencia correcta para realizar una venta?", "o": ["menu() → ventas() → proceso() → fact() → procfact()", "menu() → fact() → cargar() → ventas()", "procfact() → proceso() → menu()", "cargar() → mostrar_cj() → fact()"], "a": 0}, {"type": "mcq", "q": "¿Qué representa ventast[1][1] ?", "o": ["$230.000 vendidos por Caja 2.", "32 artículos vendidos por Caja 2.", "20 artículos vendidos por Caja 1.", "$150.000 vendidos por Caja 1."], "a": 1}, {"type": "mcq", "q": "Si op=2 , ¿qué valor recibe fact() ?", "o": ["1", "2", "3", "0"], "a": 2}, {"type": "mcq", "q": "¿Qué representa cta dentro de procfact() ?", "o": ["Cantidad de cajeros.", "Cantidad total de artículos.", "Cédula del cliente.", "Número de caja."], "a": 1}, {"type": "mcq", "q": "¿Qué representa vca ?", "o": ["Valor acumulado de la compra.", "Número de ventas.", "Cantidad de clientes.", "Día de la semana."], "a": 0}, {"type": "mcq", "q": "¿Qué ocurre en esta instrucción?", "o": ["Se envían v y c como parámetros.", "Se reciben dos valores retornados por procfact() .", "Se crea una lista.", "Se eliminan dos variables."], "a": 1}, {"type": "mcq", "q": "¿Qué función controla el programa completo?", "o": ["menu()", "fact()", "procfact()", "mostrar_cj()"], "a": 0}, {"type": "mcq", "q": "¿Cuál es el propósito principal de cargar() ?", "o": ["Registrar las ventas de un cliente.", "Capturar y almacenar los datos de los cajeros.", "Calcular el total de las cajas.", "Buscar un cajero."], "a": 1}, {"type": "mcq", "q": "¿Qué posición contiene la cédula del segundo cajero?", "o": ["datos[0]", "datos[1]", "datos[2]", "datos[3]"], "a": 2}, {"type": "mcq", "q": "¿Por qué se utiliza global i ?", "o": ["Para crear una lista llamada i .", "Para permitir que la función modifique la variable i definida fuera de ella.", "Para enviar i como parámetro.", "Para convertir i en una función."], "a": 1}, {"type": "mcq", "q": "¿Qué problema presenta este fragmento frente al requerimiento de 7 días y 24 ventas por día?", "o": ["No utiliza ninguna función.", "Los límites de los ciclos no corresponden a 7 días y 24 ventas.", "dia debería ser una lista.", "No se puede usar un while dentro de otro."], "a": 1}, {"type": "mcq", "q": "Si m es global y no vuelve a cero al iniciar un nuevo día, ¿qué puede ocurrir?", "o": ["Las ventas esperadas podrían no ejecutarse nuevamente cada día.", "Se borran automáticamente los cajeros.", "Desaparece la matriz ventast .", "Python cierra el programa."], "a": 0}, {"type": "mcq", "q": "Si se selecciona la Caja 2, ¿cuál sería una corrección apropiada?", "o": ["fact(op-1)", "fact(op)", "fact(0)", "fact(op+2)"], "a": 1}, {"type": "mcq", "q": "¿Cuál es la responsabilidad principal de fact() ?", "o": ["Registrar los cajeros.", "Recibir la caja, obtener los resultados de procfact() y acumularlos en ventast .", "Mostrar el menú principal.", "Registrar únicamente la cédula del cliente."], "a": 1}, {"type": "mcq", "q": "¿Qué hacen estas instrucciones?", "o": ["Reemplazan toda la matriz.", "Acumulan el valor vendido y los artículos de la Caja 1.", "Registran un nuevo cajero.", "Guardan la cédula del cliente."], "a": 1}, {"type": "mcq", "q": "¿Cuáles son los valores finales de cta y vca ?", "o": ["cta=2 , vca=16000", "cta=5 , vca=31000", "cta=5 , vca=26000", "cta=31000 , vca=5"], "a": 1}, {"type": "mcq", "q": "¿Qué valor debe ingresar el usuario para terminar de registrar productos?", "o": ["-1", "1", "0", "24"], "a": 2}, {"type": "mcq", "q": "¿Qué problema produce colocar el return dentro del ciclo?", "o": ["Permite registrar más productos.", "La función puede terminar después de la primera iteración.", "Reinicia automáticamente vca .", "Convierte cta en una lista."], "a": 1}, {"type": "mcq", "q": "En mostrar_cj(cd) , ¿qué representa el parámetro cd ?", "o": ["Número de productos.", "Cédula del cajero que se desea consultar.", "Valor total de ventas.", "Número del día."], "a": 1}, {"type": "code", "q": "Construya una función para calcular el valor de una compra", "description": "Construya una función llamada calcular_compra(cantidad, valor) que reciba la cantidad de artículos y el valor unitario y retorne el valor total de la compra. Ejemplo: cantidad=5, valor=8000; resultado esperado: 40000.", "starter": "def calcular_compra(cantidad, valor):\n    # Escriba aquí su solución", "rubric": "Definición de función, parámetros, operación y uso de return."}, {"type": "code", "q": "Construya una función para buscar un cajero", "description": "Utilice datos = [1010, \"Ana\", 2020, \"Luis\"]. Construya buscar_cajero(cedula) que reciba una cédula y retorne el nombre del cajero cuando exista. Si no existe, debe retornar un mensaje indicando que el cajero no existe.", "starter": "def buscar_cajero(cedula):\n    # Escriba aquí su solución", "rubric": "Parámetro, condicional, acceso a lista y retorno."}, {"type": "code", "q": "Construya una función para obtener los totales de las dos cajas", "description": "Use ventast = [[150000, 20], [230000, 32]]. Construya total_ventas() que sume el valor vendido por ambas cajas, sume la cantidad de artículos vendidos por ambas cajas, retorne los dos resultados y no solicite estos valores mediante input().", "starter": "def total_ventas():\n    # Escriba aquí su solución", "rubric": "Acceso a matriz, acumulación y retorno de dos valores."}]$json$::jsonb
    )
    returning id into v_exam_id;
  else
    update public.exams
    set subject='Programación II',
        questions=$json$[{"type": "mcq", "q": "¿Cuál es la función principal de ventas() ?", "o": ["Registrar productos.", "Verificar que existan cajeros antes de iniciar las ventas.", "Buscar clientes.", "Terminar el programa."], "a": 1}, {"type": "mcq", "q": "En def fact(p): , ¿qué representa el parámetro p ?", "o": ["Precio del producto.", "Cantidad de artículos.", "Número de caja.", "Número del cliente."], "a": 2}, {"type": "mcq", "q": "¿Qué hace return(vca,cta) ?", "o": ["Imprime dos valores.", "Guarda dos valores en datos .", "Retorna dos valores a la función que llamó a procfact() .", "Finaliza todo el programa."], "a": 2}, {"type": "mcq", "q": "¿Cuál es la secuencia correcta para realizar una venta?", "o": ["menu() → ventas() → proceso() → fact() → procfact()", "menu() → fact() → cargar() → ventas()", "procfact() → proceso() → menu()", "cargar() → mostrar_cj() → fact()"], "a": 0}, {"type": "mcq", "q": "¿Qué representa ventast[1][1] ?", "o": ["$230.000 vendidos por Caja 2.", "32 artículos vendidos por Caja 2.", "20 artículos vendidos por Caja 1.", "$150.000 vendidos por Caja 1."], "a": 1}, {"type": "mcq", "q": "Si op=2 , ¿qué valor recibe fact() ?", "o": ["1", "2", "3", "0"], "a": 2}, {"type": "mcq", "q": "¿Qué representa cta dentro de procfact() ?", "o": ["Cantidad de cajeros.", "Cantidad total de artículos.", "Cédula del cliente.", "Número de caja."], "a": 1}, {"type": "mcq", "q": "¿Qué representa vca ?", "o": ["Valor acumulado de la compra.", "Número de ventas.", "Cantidad de clientes.", "Día de la semana."], "a": 0}, {"type": "mcq", "q": "¿Qué ocurre en esta instrucción?", "o": ["Se envían v y c como parámetros.", "Se reciben dos valores retornados por procfact() .", "Se crea una lista.", "Se eliminan dos variables."], "a": 1}, {"type": "mcq", "q": "¿Qué función controla el programa completo?", "o": ["menu()", "fact()", "procfact()", "mostrar_cj()"], "a": 0}, {"type": "mcq", "q": "¿Cuál es el propósito principal de cargar() ?", "o": ["Registrar las ventas de un cliente.", "Capturar y almacenar los datos de los cajeros.", "Calcular el total de las cajas.", "Buscar un cajero."], "a": 1}, {"type": "mcq", "q": "¿Qué posición contiene la cédula del segundo cajero?", "o": ["datos[0]", "datos[1]", "datos[2]", "datos[3]"], "a": 2}, {"type": "mcq", "q": "¿Por qué se utiliza global i ?", "o": ["Para crear una lista llamada i .", "Para permitir que la función modifique la variable i definida fuera de ella.", "Para enviar i como parámetro.", "Para convertir i en una función."], "a": 1}, {"type": "mcq", "q": "¿Qué problema presenta este fragmento frente al requerimiento de 7 días y 24 ventas por día?", "o": ["No utiliza ninguna función.", "Los límites de los ciclos no corresponden a 7 días y 24 ventas.", "dia debería ser una lista.", "No se puede usar un while dentro de otro."], "a": 1}, {"type": "mcq", "q": "Si m es global y no vuelve a cero al iniciar un nuevo día, ¿qué puede ocurrir?", "o": ["Las ventas esperadas podrían no ejecutarse nuevamente cada día.", "Se borran automáticamente los cajeros.", "Desaparece la matriz ventast .", "Python cierra el programa."], "a": 0}, {"type": "mcq", "q": "Si se selecciona la Caja 2, ¿cuál sería una corrección apropiada?", "o": ["fact(op-1)", "fact(op)", "fact(0)", "fact(op+2)"], "a": 1}, {"type": "mcq", "q": "¿Cuál es la responsabilidad principal de fact() ?", "o": ["Registrar los cajeros.", "Recibir la caja, obtener los resultados de procfact() y acumularlos en ventast .", "Mostrar el menú principal.", "Registrar únicamente la cédula del cliente."], "a": 1}, {"type": "mcq", "q": "¿Qué hacen estas instrucciones?", "o": ["Reemplazan toda la matriz.", "Acumulan el valor vendido y los artículos de la Caja 1.", "Registran un nuevo cajero.", "Guardan la cédula del cliente."], "a": 1}, {"type": "mcq", "q": "¿Cuáles son los valores finales de cta y vca ?", "o": ["cta=2 , vca=16000", "cta=5 , vca=31000", "cta=5 , vca=26000", "cta=31000 , vca=5"], "a": 1}, {"type": "mcq", "q": "¿Qué valor debe ingresar el usuario para terminar de registrar productos?", "o": ["-1", "1", "0", "24"], "a": 2}, {"type": "mcq", "q": "¿Qué problema produce colocar el return dentro del ciclo?", "o": ["Permite registrar más productos.", "La función puede terminar después de la primera iteración.", "Reinicia automáticamente vca .", "Convierte cta en una lista."], "a": 1}, {"type": "mcq", "q": "En mostrar_cj(cd) , ¿qué representa el parámetro cd ?", "o": ["Número de productos.", "Cédula del cajero que se desea consultar.", "Valor total de ventas.", "Número del día."], "a": 1}, {"type": "code", "q": "Construya una función para calcular el valor de una compra", "description": "Construya una función llamada calcular_compra(cantidad, valor) que reciba la cantidad de artículos y el valor unitario y retorne el valor total de la compra. Ejemplo: cantidad=5, valor=8000; resultado esperado: 40000.", "starter": "def calcular_compra(cantidad, valor):\n    # Escriba aquí su solución", "rubric": "Definición de función, parámetros, operación y uso de return."}, {"type": "code", "q": "Construya una función para buscar un cajero", "description": "Utilice datos = [1010, \"Ana\", 2020, \"Luis\"]. Construya buscar_cajero(cedula) que reciba una cédula y retorne el nombre del cajero cuando exista. Si no existe, debe retornar un mensaje indicando que el cajero no existe.", "starter": "def buscar_cajero(cedula):\n    # Escriba aquí su solución", "rubric": "Parámetro, condicional, acceso a lista y retorno."}, {"type": "code", "q": "Construya una función para obtener los totales de las dos cajas", "description": "Use ventast = [[150000, 20], [230000, 32]]. Construya total_ventas() que sume el valor vendido por ambas cajas, sume la cantidad de artículos vendidos por ambas cajas, retorne los dos resultados y no solicite estos valores mediante input().", "starter": "def total_ventas():\n    # Escriba aquí su solución", "rubric": "Acceso a matriz, acumulación y retorno de dos valores."}]$json$::jsonb
    where id=v_exam_id;
  end if;

  insert into public.exam_publications(exam_id,group_name,active,published_at)
  values(v_exam_id,'H',true,now())
  on conflict (exam_id,group_name)
  do update set active=true,published_at=now();
end $$;

-- 3) Entrega segura.
-- Las preguntas 1–22 se mezclan; las 23–25 siempre quedan al final.
create or replace function public.get_active_exam_secure(p_cedula text,p_device_id text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_student record;
  v_pub record;
  v_exam record;
  v_attempt record;
  v_total int;
  v_order jsonb;
  v_questions jsonb;
  v_token text;
begin
  if nullif(btrim(p_device_id),'') is null then
    return jsonb_build_object('ok',false,'message','No fue posible identificar este dispositivo.');
  end if;

  select sr.cedula, sr.name, en.group_name, en.subject
  into v_student
  from public.student_registry sr
  join public.student_enrollments en on en.cedula=sr.cedula
  join public.exam_publications ep on ep.group_name=en.group_name and ep.active=true
  join public.exams e on e.id=ep.exam_id
    and lower(replace(e.subject,'ó','o'))=lower(replace(en.subject,'ó','o'))
  where sr.cedula=btrim(p_cedula)
  order by ep.published_at desc
  limit 1;

  if not found then
    select sr.cedula, sr.name, sr."group" as group_name, cg.subject
    into v_student
    from public.student_registry sr
    join public.class_groups cg on cg.group_name=sr."group"
    join public.exam_publications ep on ep.group_name=sr."group" and ep.active=true
    join public.exams e on e.id=ep.exam_id
      and lower(replace(e.subject,'ó','o'))=lower(replace(cg.subject,'ó','o'))
    where sr.cedula=btrim(p_cedula)
    order by ep.published_at desc
    limit 1;
  end if;

  if not found then
    return jsonb_build_object('ok',false,'message','No se encontró una evaluación activa para la matrícula de esta cédula.');
  end if;

  select ep.*
  into v_pub
  from public.exam_publications ep
  join public.exams e on e.id=ep.exam_id
  where ep.group_name=v_student.group_name
    and ep.active=true
    and lower(replace(e.subject,'ó','o'))=lower(replace(v_student.subject,'ó','o'))
  order by ep.published_at desc
  limit 1;

  if not found then
    return jsonb_build_object('ok',false,'message','No hay una evaluación activa para tu grupo '||v_student.group_name||'.');
  end if;

  if exists(
    select 1 from public.exam_results
    where exam_id=v_pub.exam_id and cedula=v_student.cedula and group_name=v_student.group_name
  ) then
    return jsonb_build_object('ok',false,'message','Esta evaluación ya fue presentada.');
  end if;

  select * into v_exam from public.exams where id=v_pub.exam_id;
  v_total=jsonb_array_length(v_exam.questions);

  select * into v_attempt
  from public.exam_attempts
  where exam_id=v_pub.exam_id and cedula=v_student.cedula and group_name=v_student.group_name
  limit 1;

  if found then
    if v_attempt.device_id<>p_device_id then
      return jsonb_build_object('ok',false,'message','Esta evaluación ya fue iniciada en otro dispositivo. No puede trasladarse ni compartirse.');
    end if;
    if not v_attempt.active then
      return jsonb_build_object('ok',false,'message','Este intento ya fue cerrado.');
    end if;
    v_order=v_attempt.question_order;
    v_token=v_attempt.access_token;
    update public.exam_attempts set last_seen_at=now() where id=v_attempt.id;
  else
    select jsonb_agg(idx order by grp, rnd nulls last, idx)
    into v_order
    from (
      select
        i as idx,
        case when coalesce((v_exam.questions->i)->>'type','mcq')='code' then 1 else 0 end as grp,
        case when coalesce((v_exam.questions->i)->>'type','mcq')='code' then null else random() end as rnd
      from generate_series(0,v_total-1) g(i)
    ) s;

    v_token=md5(random()::text || clock_timestamp()::text || p_cedula || p_device_id);

    insert into public.exam_attempts(exam_id,cedula,group_name,device_id,access_token,question_order)
    values(v_exam.id,v_student.cedula,v_student.group_name,p_device_id,v_token,v_order);
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'type',coalesce((v_exam.questions->((x.value)::int))->>'type','mcq'),
      'q',(v_exam.questions->((x.value)::int))->>'q',
      'o',(v_exam.questions->((x.value)::int))->'o',
      'description',(v_exam.questions->((x.value)::int))->>'description',
      'starter',(v_exam.questions->((x.value)::int))->>'starter',
      'rubric',(v_exam.questions->((x.value)::int))->>'rubric'
    )
    order by x.ord
  )
  into v_questions
  from jsonb_array_elements_text(v_order) with ordinality as x(value,ord);

  return jsonb_build_object(
    'ok',true,
    'exam_id',v_exam.id,
    'title',v_exam.title,
    'subject',v_exam.subject,
    'student_name',v_student.name,
    'group_name',v_student.group_name,
    'questions',v_questions,
    'access_token',v_token
  );
end;
$$;

grant execute on function public.get_active_exam_secure(text,text) to anon,authenticated;

-- 4) Envío: selección automática (3.5 puntos) + código pendiente (1.5 puntos).
create or replace function public.submit_exam_secure(
  p_access_token text,p_device_id text,p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_attempt record;
  v_exam record;
  v_total int;
  v_mcq_total int:=0;
  v_correct int:=0;
  v_i int;
  v_original_index int;
  v_type text;
  v_auto numeric(3,2);
  v_student_name text;
begin
  select * into v_attempt
  from public.exam_attempts
  where access_token=p_access_token and active=true
  limit 1;

  if not found then raise exception 'Intento no válido o ya cerrado'; end if;
  if v_attempt.device_id<>p_device_id then raise exception 'Dispositivo no autorizado'; end if;

  if not exists(
    select 1 from public.exam_publications
    where exam_id=v_attempt.exam_id and group_name=v_attempt.group_name and active=true
  ) then
    raise exception 'La evaluación ya no está activa para este grupo';
  end if;

  if exists(
    select 1 from public.exam_results
    where exam_id=v_attempt.exam_id and cedula=v_attempt.cedula and group_name=v_attempt.group_name
  ) then
    raise exception 'La evaluación ya fue presentada';
  end if;

  select * into v_exam from public.exams where id=v_attempt.exam_id;
  v_total=jsonb_array_length(v_exam.questions);

  if jsonb_array_length(p_answers)<>v_total then
    raise exception 'Cantidad de respuestas inválida';
  end if;

  for v_i in 0..v_total-1 loop
    v_original_index=(v_attempt.question_order->>v_i)::int;
    v_type=coalesce((v_exam.questions->v_original_index)->>'type','mcq');

    if v_type='mcq' then
      v_mcq_total=v_mcq_total+1;
      begin
        if (p_answers->>v_i)::int =
           ((v_exam.questions->v_original_index)->>'a')::int then
          v_correct=v_correct+1;
        end if;
      exception when others then
        null;
      end;
    end if;
  end loop;

  select name into v_student_name
  from public.student_registry
  where cedula=v_attempt.cedula
  limit 1;

  v_auto=case when v_mcq_total>0
    then round((v_correct::numeric/v_mcq_total::numeric)*3.5,2)
    else 0 end;

  insert into public.exam_results(
    exam_id,cedula,student_name,group_name,correct_answers,total_questions,
    grade,status,security_violations,security_status,
    answers,auto_points,manual_points,manual_pending
  )
  values(
    v_attempt.exam_id,
    v_attempt.cedula,
    coalesce(v_student_name,v_attempt.cedula),
    v_attempt.group_name,
    v_correct,
    v_mcq_total,
    v_auto,
    'PENDIENTE REVISIÓN',
    v_attempt.security_violations,
    case when v_attempt.security_violations>0 then 'REVISAR' else 'NORMAL' end,
    p_answers,
    v_auto,
    0,
    true
  );

  update public.exam_attempts
  set active=false,last_seen_at=now()
  where id=v_attempt.id;

  return jsonb_build_object(
    'ok',true,
    'message','Evaluación enviada. Las preguntas 23–25 quedaron pendientes de revisión docente.'
  );
end;
$$;

grant execute on function public.submit_exam_secure(text,text,jsonb) to anon,authenticated;

-- 5) Verificación: debe mostrar 25 preguntas y Grupo H activo.
select
  e.id,e.title,e.subject,
  jsonb_array_length(e.questions) as numero_preguntas,
  (e.questions->22)->>'type' as pregunta_23_tipo,
  (e.questions->23)->>'type' as pregunta_24_tipo,
  (e.questions->24)->>'type' as pregunta_25_tipo,
  ep.group_name,ep.active
from public.exams e
left join public.exam_publications ep on ep.exam_id=e.id
where e.title='Revisión de Conocimientos de Funciones'
  and lower(replace(e.subject,'ó','o'))='programacion ii'
order by e.id,ep.group_name;
