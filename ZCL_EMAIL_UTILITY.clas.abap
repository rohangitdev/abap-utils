CLASS zcl_email_utility DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "--------------------------------------------------------------------
    " Type definitions
    "--------------------------------------------------------------------
    TYPES:
      BEGIN OF ty_recipient,
        address TYPE ad_smtpadr,   " e.g. user@example.com
        name    TYPE ad_name1,     " Display name
        type    TYPE char1,        " T=To, C=CC, B=BCC
      END OF ty_recipient,
      tt_recipients TYPE STANDARD TABLE OF ty_recipient WITH DEFAULT KEY,

      BEGIN OF ty_attachment,
        content   TYPE xstring,    " Binary content
        filename  TYPE string,     " e.g. 'report.pdf'
        mime_type TYPE string,     " e.g. 'application/pdf'
      END OF ty_attachment,
      tt_attachments TYPE STANDARD TABLE OF ty_attachment WITH DEFAULT KEY,

      BEGIN OF ty_placeholder,
        key   TYPE string,         " Placeholder key, e.g. 'CUSTOMER_NAME'
        value TYPE string,         " Replacement value
      END OF ty_placeholder,
      tt_placeholders TYPE STANDARD TABLE OF ty_placeholder WITH DEFAULT KEY.

    "--------------------------------------------------------------------
    "! <p class="shorttext synchronized" lang="en">Send a plain or HTML email</p>
    "--------------------------------------------------------------------
    CLASS-METHODS send_email
      IMPORTING
        !it_recipients  TYPE tt_recipients
        !iv_subject     TYPE string
        !iv_body        TYPE string
        !iv_is_html     TYPE abap_bool DEFAULT abap_false
        !iv_sender      TYPE ad_smtpadr OPTIONAL
      RETURNING
        VALUE(rv_success) TYPE abap_bool
      RAISING
        cx_bcs.

    "--------------------------------------------------------------------
    "! <p class="shorttext synchronized" lang="en">Send email using a template with placeholder substitution</p>
    "! Template placeholders use {KEY} syntax, e.g. {CUSTOMER_NAME}
    "--------------------------------------------------------------------
    CLASS-METHODS send_email_with_template
      IMPORTING
        !iv_template_body  TYPE string
        !it_placeholders   TYPE tt_placeholders
        !it_recipients     TYPE tt_recipients
        !iv_subject        TYPE string
        !iv_is_html        TYPE abap_bool DEFAULT abap_false
        !iv_sender         TYPE ad_smtpadr OPTIONAL
      RETURNING
        VALUE(rv_success) TYPE abap_bool
      RAISING
        cx_bcs.

    "--------------------------------------------------------------------
    "! <p class="shorttext synchronized" lang="en">Send email with one or more file attachments</p>
    "--------------------------------------------------------------------
    CLASS-METHODS send_email_with_attachment
      IMPORTING
        !it_recipients  TYPE tt_recipients
        !iv_subject     TYPE string
        !iv_body        TYPE string
        !iv_is_html     TYPE abap_bool DEFAULT abap_false
        !it_attachments TYPE tt_attachments
        !iv_sender      TYPE ad_smtpadr OPTIONAL
      RETURNING
        VALUE(rv_success) TYPE abap_bool
      RAISING
        cx_bcs.

    "--------------------------------------------------------------------
    "! <p class="shorttext synchronized" lang="en">Send email with template substitution AND attachments</p>
    "! Combines template rendering + multi-attachment support
    "--------------------------------------------------------------------
    CLASS-METHODS send_email_full
      IMPORTING
        !iv_template_body  TYPE string
        !it_placeholders   TYPE tt_placeholders
        !it_recipients     TYPE tt_recipients
        !iv_subject        TYPE string
        !iv_is_html        TYPE abap_bool DEFAULT abap_false
        !it_attachments    TYPE tt_attachments
        !iv_sender         TYPE ad_smtpadr OPTIONAL
      RETURNING
        VALUE(rv_success) TYPE abap_bool
      RAISING
        cx_bcs.

  PRIVATE SECTION.

    "--------------------------------------------------------------------
    "! Replace {KEY} placeholders in template with actual values
    "--------------------------------------------------------------------
    CLASS-METHODS _fill_template
      IMPORTING
        !iv_template      TYPE string
        !it_placeholders  TYPE tt_placeholders
      RETURNING
        VALUE(rv_result)  TYPE string.

    "--------------------------------------------------------------------
    "! Build a BCS send request and trigger dispatch
    "--------------------------------------------------------------------
    CLASS-METHODS _build_and_send
      IMPORTING
        !it_recipients    TYPE tt_recipients
        !iv_subject       TYPE string
        !iv_body          TYPE string
        !iv_is_html       TYPE abap_bool DEFAULT abap_false
        !it_attachments   TYPE tt_attachments
        !iv_sender        TYPE ad_smtpadr OPTIONAL
      RETURNING
        VALUE(rv_success) TYPE abap_bool
      RAISING
        cx_bcs.

ENDCLASS.


CLASS zcl_email_utility IMPLEMENTATION.

  METHOD send_email.
    rv_success = _build_and_send(
      it_recipients  = it_recipients
      iv_subject     = iv_subject
      iv_body        = iv_body
      iv_is_html     = iv_is_html
      it_attachments = VALUE tt_attachments( )
      iv_sender      = iv_sender ).
  ENDMETHOD.


  METHOD send_email_with_template.
    " Substitute placeholders in the template
    DATA(lv_rendered_body) = _fill_template(
      iv_template     = iv_template_body
      it_placeholders = it_placeholders ).

    rv_success = _build_and_send(
      it_recipients  = it_recipients
      iv_subject     = iv_subject
      iv_body        = lv_rendered_body
      iv_is_html     = iv_is_html
      it_attachments = VALUE tt_attachments( )
      iv_sender      = iv_sender ).
  ENDMETHOD.


  METHOD send_email_with_attachment.
    rv_success = _build_and_send(
      it_recipients  = it_recipients
      iv_subject     = iv_subject
      iv_body        = iv_body
      iv_is_html     = iv_is_html
      it_attachments = it_attachments
      iv_sender      = iv_sender ).
  ENDMETHOD.


  METHOD send_email_full.
    " Substitute placeholders in the template
    DATA(lv_rendered_body) = _fill_template(
      iv_template     = iv_template_body
      it_placeholders = it_placeholders ).

    rv_success = _build_and_send(
      it_recipients  = it_recipients
      iv_subject     = iv_subject
      iv_body        = lv_rendered_body
      iv_is_html     = iv_is_html
      it_attachments = it_attachments
      iv_sender      = iv_sender ).
  ENDMETHOD.


  METHOD _fill_template.
    rv_result = iv_template.
    LOOP AT it_placeholders ASSIGNING FIELD-SYMBOL(<ph>).
      DATA(lv_token) = |{ '{' }{ <ph>-key }{ '}' }|.
      REPLACE ALL OCCURRENCES OF lv_token IN rv_result WITH <ph>-value.
    ENDLOOP.
  ENDMETHOD.


  METHOD _build_and_send.
    TRY.
        " ---- 1. Create send request --------------------------------
        DATA(lo_send_req) = cl_bcs=>create_persistent( ).

        " ---- 2. Set sender -----------------------------------------
        IF iv_sender IS NOT INITIAL.
          DATA(lo_sender) = cl_cam_address_bcs=>create_internet_address(
                              i_address_string = CONV ad_smtpadr( iv_sender ) ).
          lo_send_req->set_sender( i_sender = lo_sender ).
        ENDIF.

        " ---- 3. Add recipients ------------------------------------
        LOOP AT it_recipients ASSIGNING FIELD-SYMBOL(<rcpt>).
          DATA(lo_recipient) = cl_cam_address_bcs=>create_internet_address(
                                 i_address_string = <rcpt>-address
                                 i_address_name   = CONV char40( <rcpt>-name ) ).

          DATA(lv_copy_type) = SWITCH so_snd_art(
            <rcpt>-type
            WHEN 'C' THEN 'CC'
            WHEN 'B' THEN 'BCC'
            ELSE          'INT' ).

          lo_send_req->add_recipient(
            i_recipient  = lo_recipient
            i_copy       = COND #( WHEN lv_copy_type = 'CC'  THEN abap_true ELSE abap_false )
            i_blind_copy = COND #( WHEN lv_copy_type = 'BCC' THEN abap_true ELSE abap_false ) ).
        ENDLOOP.

        " ---- 4. Create document (body) ----------------------------
        DATA(lv_body_string) = iv_body.

        " Split body into 255-char lines (BCS requirement)
        DATA lt_body_lines TYPE bcsy_text.
        DATA lv_offset     TYPE i VALUE 0.
        DATA lv_len        TYPE i.
        lv_len = strlen( lv_body_string ).

        WHILE lv_offset < lv_len.
          DATA(lv_chunk_len) = COND i(
            WHEN ( lv_len - lv_offset ) > 255 THEN 255
            ELSE lv_len - lv_offset ).
          APPEND CONV char255( lv_body_string+lv_offset(lv_chunk_len) ) TO lt_body_lines.
          lv_offset = lv_offset + lv_chunk_len.
        ENDWHILE.

        DATA(lv_doc_type) = COND so_obj_tp(
          WHEN iv_is_html = abap_true THEN 'HTM'
          ELSE                             'RAW' ).

        DATA(lo_doc) = cl_document_bcs=>create_document(
          i_type    = lv_doc_type
          i_text    = lt_body_lines
          i_subject = CONV so_obj_des( iv_subject ) ).

        " ---- 5. Add attachments -----------------------------------
        LOOP AT it_attachments ASSIGNING FIELD-SYMBOL(<att>).
          " Determine hex size
          DATA(lv_size) = xstrlen( <att>-content ).

          lo_doc->add_attachment(
            i_attachment_type    = CONV so_obj_tp(
                                     COND #(
                                       WHEN <att>-mime_type CO 'application/pdf' THEN 'PDF'
                                       WHEN <att>-mime_type CO 'text/plain'      THEN 'TXT'
                                       WHEN <att>-mime_type CO 'text/html'       THEN 'HTM'
                                       WHEN <att>-mime_type CO 'image/png'       THEN 'PNG'
                                       WHEN <att>-mime_type CO 'image/jpeg'      THEN 'JPG'
                                       WHEN <att>-mime_type CO 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                                                                                  THEN 'XLS'
                                       ELSE 'BIN' ) )
            i_attachment_subject = CONV so_obj_des( <att>-filename )
            i_att_content_hex    = <att>-content ).
        ENDLOOP.

        " ---- 6. Set document on request --------------------------
        lo_send_req->set_document( lo_doc ).

        " ---- 7. Send immediately ---------------------------------
        lo_send_req->set_send_immediately( abap_true ).

        " ---- 8. Trigger send -------------------------------------
        lo_send_req->send( i_with_error_screen = abap_false ).

        COMMIT WORK.

        rv_success = abap_true.

      CATCH cx_bcs INTO DATA(lx_bcs).
        " Log the error - callers may catch cx_bcs upstream
        rv_success = abap_false.
        RAISE EXCEPTION lx_bcs.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
