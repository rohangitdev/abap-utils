CLASS zcl_abap_utils DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! <p class="shorttext synchronized" lang="en">Convert internal table to string (CSV format)</p>
    CLASS-METHODS itab_to_csv
      IMPORTING
        !it_data       TYPE STANDARD TABLE
        !iv_delimiter  TYPE char1 DEFAULT ','
        !iv_header     TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_csv)  TYPE string
      RAISING
        cx_sy_conversion_error.

    "! <p class="shorttext synchronized" lang="en">Split string by delimiter into internal table</p>
    CLASS-METHODS string_to_itab
      IMPORTING
        !iv_string    TYPE string
        !iv_delimiter TYPE char1 DEFAULT ','
      RETURNING
        VALUE(rt_result) TYPE string_table.

    "! <p class="shorttext synchronized" lang="en">Convert XSTRING to STRING (Base64 encode)</p>
    CLASS-METHODS xstring_to_base64
      IMPORTING
        !iv_xstring        TYPE xstring
      RETURNING
        VALUE(rv_base64)   TYPE string.

    "! <p class="shorttext synchronized" lang="en">Convert Base64 string to XSTRING</p>
    CLASS-METHODS base64_to_xstring
      IMPORTING
        !iv_base64         TYPE string
      RETURNING
        VALUE(rv_xstring)  TYPE xstring.

    "! <p class="shorttext synchronized" lang="en">Pad string to left with character</p>
    CLASS-METHODS lpad
      IMPORTING
        !iv_string    TYPE string
        !iv_length    TYPE i
        !iv_char      TYPE char1 DEFAULT ' '
      RETURNING
        VALUE(rv_result) TYPE string.

    "! <p class="shorttext synchronized" lang="en">Pad string to right with character</p>
    CLASS-METHODS rpad
      IMPORTING
        !iv_string    TYPE string
        !iv_length    TYPE i
        !iv_char      TYPE char1 DEFAULT ' '
      RETURNING
        VALUE(rv_result) TYPE string.

    "! <p class="shorttext synchronized" lang="en">Replace all occurrences of a substring</p>
    CLASS-METHODS replace_all
      IMPORTING
        !iv_string      TYPE string
        !iv_search      TYPE string
        !iv_replace     TYPE string
      RETURNING
        VALUE(rv_result) TYPE string.

    "! <p class="shorttext synchronized" lang="en">Check if string contains substring (case-insensitive)</p>
    CLASS-METHODS contains_string
      IMPORTING
        !iv_string    TYPE string
        !iv_substring TYPE string
        !iv_case_sensitive TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_found) TYPE abap_bool.

    "! <p class="shorttext synchronized" lang="en">Get current timestamp as formatted string</p>
    CLASS-METHODS get_timestamp
      IMPORTING
        !iv_format    TYPE string DEFAULT 'YYYYMMDDHHMMSS'
      RETURNING
        VALUE(rv_timestamp) TYPE string.

    "! <p class="shorttext synchronized" lang="en">Convert date to string in given format</p>
    CLASS-METHODS date_to_string
      IMPORTING
        !iv_date      TYPE d
        !iv_format    TYPE string DEFAULT 'DD.MM.YYYY'
      RETURNING
        VALUE(rv_result) TYPE string.

    "! <p class="shorttext synchronized" lang="en">Generate a UUID (GUID) string</p>
    CLASS-METHODS generate_guid
      RETURNING
        VALUE(rv_guid) TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_abap_utils IMPLEMENTATION.

  METHOD itab_to_csv.
    DATA: lv_line   TYPE string,
          lv_value  TYPE string,
          lt_fields TYPE string_table.

    " Get field catalog from the table
    DATA(lo_descr) = CAST cl_abap_tabledescr(
                       cl_abap_typedescr=>describe_by_data( it_data ) ).
    DATA(lo_struct) = CAST cl_abap_structdescr(
                       lo_descr->get_table_line_type( ) ).

    " Header row
    IF iv_header = abap_true.
      CLEAR lt_fields.
      LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<comp>).
        APPEND CONV string( <comp>-name ) TO lt_fields.
      ENDLOOP.
      rv_csv = concat_lines_of( table = lt_fields sep = iv_delimiter ) && cl_abap_char_utilities=>newline.
    ENDIF.

    " Data rows
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<row>).
      CLEAR lt_fields.
      LOOP AT lo_struct->components ASSIGNING FIELD-SYMBOL(<field>).
        ASSIGN COMPONENT <field>-name OF STRUCTURE <row> TO FIELD-SYMBOL(<val>).
        IF sy-subrc = 0.
          lv_value = <val>.
          " Escape double quotes and wrap in quotes if contains delimiter
          IF lv_value CS iv_delimiter OR lv_value CS '"'.
            REPLACE ALL OCCURRENCES OF '"' IN lv_value WITH '""'.
            lv_value = |"{ lv_value }"|.
          ENDIF.
          APPEND lv_value TO lt_fields.
        ENDIF.
      ENDLOOP.
      rv_csv = rv_csv && concat_lines_of( table = lt_fields sep = iv_delimiter )
                      && cl_abap_char_utilities=>newline.
    ENDLOOP.
  ENDMETHOD.


  METHOD string_to_itab.
    SPLIT iv_string AT iv_delimiter INTO TABLE rt_result.
    LOOP AT rt_result ASSIGNING FIELD-SYMBOL(<item>).
      <item> = condense( val = <item> ).
    ENDLOOP.
  ENDMETHOD.


  METHOD xstring_to_base64.
    rv_base64 = cl_http_utility=>encode_x_base64( iv_xstring ).
  ENDMETHOD.


  METHOD base64_to_xstring.
    rv_xstring = cl_http_utility=>decode_x_base64( iv_base64 ).
  ENDMETHOD.


  METHOD lpad.
    rv_result = iv_string.
    WHILE strlen( rv_result ) < iv_length.
      rv_result = iv_char && rv_result.
    ENDWHILE.
  ENDMETHOD.


  METHOD rpad.
    rv_result = iv_string.
    WHILE strlen( rv_result ) < iv_length.
      rv_result = rv_result && iv_char.
    ENDWHILE.
  ENDMETHOD.


  METHOD replace_all.
    rv_result = iv_string.
    REPLACE ALL OCCURRENCES OF iv_search IN rv_result WITH iv_replace.
  ENDMETHOD.


  METHOD contains_string.
    IF iv_case_sensitive = abap_true.
      IF iv_string CS iv_substring.
        rv_found = abap_true.
      ENDIF.
    ELSE.
      DATA(lv_upper_string) = to_upper( iv_string ).
      DATA(lv_upper_sub)    = to_upper( iv_substring ).
      IF lv_upper_string CS lv_upper_sub.
        rv_found = abap_true.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD get_timestamp.
    DATA: lv_date TYPE d,
          lv_time TYPE t,
          lv_result TYPE string.

    GET TIME FIELD lv_time.
    GET DATE FIELD lv_date.

    lv_result = iv_format.
    REPLACE ALL OCCURRENCES OF 'YYYY' IN lv_result WITH lv_date(4).
    REPLACE ALL OCCURRENCES OF 'MM'   IN lv_result WITH lv_date+4(2).
    REPLACE ALL OCCURRENCES OF 'DD'   IN lv_result WITH lv_date+6(2).
    REPLACE ALL OCCURRENCES OF 'HH'   IN lv_result WITH lv_time(2).
    REPLACE ALL OCCURRENCES OF 'MM'   IN lv_result WITH lv_time+2(2).
    REPLACE ALL OCCURRENCES OF 'SS'   IN lv_result WITH lv_time+4(2).

    rv_timestamp = lv_result.
  ENDMETHOD.


  METHOD date_to_string.
    rv_result = iv_format.
    REPLACE ALL OCCURRENCES OF 'YYYY' IN rv_result WITH iv_date(4).
    REPLACE ALL OCCURRENCES OF 'YY'   IN rv_result WITH iv_date+2(2).
    REPLACE ALL OCCURRENCES OF 'MM'   IN rv_result WITH iv_date+4(2).
    REPLACE ALL OCCURRENCES OF 'DD'   IN rv_result WITH iv_date+6(2).
  ENDMETHOD.


  METHOD generate_guid.
    DATA lv_guid TYPE sysuuid_x16.
    TRY.
        lv_guid = cl_system_uuid=>create_uuid_x16_static( ).
        rv_guid = cl_system_uuid=>if_system_uuid~convert_uuid_x16_to_c32(
                    uuid = lv_guid ).
      CATCH cx_uuid_error INTO DATA(lx_error).
        rv_guid = ''.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
