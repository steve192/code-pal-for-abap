*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lcl_exemption_base IMPLEMENTATION.

  METHOD constructor.
    me->database_access = database_access.
    me->object_type = object_type.
    me->object_name = object_name.
    me->include = include.
  ENDMETHOD.


  METHOD is_exempt.
    result = xsdbool( has_tadir_generated_flag( )
                   OR has_trdir_generated_flag( ) ).
  ENDMETHOD.


  METHOD has_tadir_generated_flag.
    DATA(tadir) = database_access->get_tadir( object_type = object_type
                                              object_name = object_name ).

    result = xsdbool( line_exists( tadir[ genflag = abap_true ] ) ).
  ENDMETHOD.


  METHOD has_trdir_generated_flag.
    DATA(trdir) = database_access->get_trdir( include ).

    result = xsdbool( line_exists( trdir[ occurs = abap_true ] ) ).
  ENDMETHOD.

ENDCLASS.



CLASS lcl_exemption_of_clas IMPLEMENTATION.

  METHOD is_exempt.
    result = super->is_exempt( ).

    IF result = abap_true.
      RETURN.
    ENDIF.

    DATA(definitions) = database_access->get_class_definition( CONV #( object_name ) ).

    SORT definitions BY version.
    class_header_data = definitions[ 1 ].

    result = xsdbool( is_odata_generate( )
                   OR is_ecatt_odata_test_generate( )
                   OR is_fin_infotype_generate( )
                   OR is_shma_generate( )
                   OR is_proxy_generate( )
                   OR is_sadl_generate( )
                   OR is_exit_class( )
                   OR is_exception_class( )
                   OR is_reference_exempted( object_name ) ).
  ENDMETHOD.


  METHOD is_reference_exempted.
    DATA exempt_references TYPE STANDARD TABLE OF seometarel-refclsname.

    " BSP application
    exempt_references = VALUE #( ( 'CL_BSP_WD_COMPONENT_CONTROLLER' )
                                 ( 'CL_BSP_WD_CONTEXT' )
                                 ( 'CL_BSP_WD_CONTEXT_NODE' )
                                 ( 'CL_BSP_WD_WINDOW' )
                                 ( 'CL_BSP_WD_CUSTOM_CONTROLLER' )
                                 ( 'CL_BSP_WD_VIEW_CONTROLLER' )
                                 ( 'CL_BSP_WD_ADVSEARCH_CONTROLLER' )
                                 ( 'CL_BSP_WD_CONTEXT_NODE_ASP' ) ).

    " extensibility generated objects
    exempt_references = VALUE #( BASE exempt_references
                               ( 'IF_CFD_ODATA_MPC_FLX' )
                               ( 'IF_CFD_ODATA_DPC_FLX' ) ).

    " service maintenance UI
    exempt_references = VALUE #( BASE exempt_references
                               ( '/FTI/IF_FTI_MODEL' ) ).

    " SQL routines
    exempt_references = VALUE #( BASE exempt_references
                               ( '/FTI/IF_NATIVE_SQL_GENERATOR' ) ).

    DATA(metadatas) = database_access->get_class_metadata( CONV #( class_name ) ).

    LOOP AT metadatas ASSIGNING FIELD-SYMBOL(<metadata>).
      IF line_exists( exempt_references[ table_line = <metadata>-refclsname ] ).
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.

    LOOP AT metadatas ASSIGNING <metadata>.
      IF is_reference_exempted( CONV #( <metadata>-refclsname ) ).
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD is_ecatt_odata_test_generate.
    result = xsdbool( class_header_data-author = 'eCATTClassGe' ).
  ENDMETHOD.


  METHOD is_exception_class.
    CONSTANTS exception_clase_type LIKE class_header_data-category VALUE '40'.
    result = xsdbool( class_header_data-category = exception_clase_type ).
  ENDMETHOD.


  METHOD is_exit_class.
    CONSTANTS exit_class_type LIKE class_header_data-category VALUE '01'.
    result = xsdbool( class_header_data-category = exit_class_type ).
  ENDMETHOD.


  METHOD is_fin_infotype_generate.
    DATA(t777ditclass) = database_access->get_hrbas_infotype( CONV #( object_name ) ).
    result = xsdbool( lines( t777ditclass ) > 0 ).
  ENDMETHOD.


  METHOD is_odata_generate.
    DATA(sbd_ga) = database_access->get_service_builder_artifact( object_type = object_type
                                                                  object_name = object_name ).

    result = xsdbool( line_exists( sbd_ga[ gen_art_type = 'DPCB' ] )
                   OR line_exists( sbd_ga[ gen_art_type = 'MPCB' ] ) ).
  ENDMETHOD.


  METHOD is_proxy_generate.
    result = xsdbool( class_header_data-clsproxy = abap_true ).
  ENDMETHOD.


  METHOD is_sadl_generate.
    DATA(description) = database_access->repository_access->get_class_description( CONV #( object_name ) ).
    result = xsdbool( description = 'Generated by SADL Generation Toolkit' ).
  ENDMETHOD.


  METHOD is_shma_generate.
    CONSTANTS shma_type LIKE class_header_data-category VALUE '45'.
    result = xsdbool( class_header_data-category = shma_type ).
  ENDMETHOD.

ENDCLASS.



CLASS lcl_exemption_of_fugr IMPLEMENTATION.

  METHOD is_exempt.
    result = super->is_exempt( ).

    IF is_function_module( ) = abap_false
    OR result = abap_true.
      RETURN.
    ENDIF.

    function_module = get_function_module( ).
    function_module_attributes = get_function_attributes( ).

    result = xsdbool( is_generated( )
                   OR is_obsolete( )
                   OR is_rai_generate( ) ).
  ENDMETHOD.


  METHOD is_function_module.
    DATA(function_include_pattern) = |{ object_name }U|.
    result = xsdbool( include CS function_include_pattern ).
  ENDMETHOD.


  METHOD get_function_module.
    DATA(function_modules) = database_access->repository_access->get_functions_of_function_pool( CONV #( object_name ) ).
    result = function_modules[ include = include ]-funcname.
  ENDMETHOD.


  METHOD get_function_attributes.
    DATA(attributes) = database_access->get_function_attributes( function_module ).
    result = attributes[ 1 ].
  ENDMETHOD.


  METHOD is_generated.
    result = function_module_attributes-generated.
  ENDMETHOD.


  METHOD is_obsolete.
    result = function_module_attributes-exten5.
  ENDMETHOD.


  METHOD is_rai_generate.
    CHECK function_module CP '*_RAI_*'.

    result = xsdbool( function_module CP '*_UPDATE'
                   OR function_module CP '*_INSERT'
                   OR function_module CP '*_CREATE_API' ).
  ENDMETHOD.

ENDCLASS.



CLASS lcl_exemption_of_prog IMPLEMENTATION.

  METHOD is_exempt.
    result = xsdbool( super->is_exempt( )
                   OR is_downport_assist_generate( )
                   OR is_fin_infotyp_generate( )
                   OR is_object_sw01_generate( ) ).
  ENDMETHOD.


  METHOD is_downport_assist_generate.
    result = xsdbool( object_name CP 'NOTE_*'
                   OR object_name CP 'SAP_NOTE_*'
                   OR object_name CP '_NOTE_*').
  ENDMETHOD.


  METHOD is_fin_infotyp_generate.
    result = xsdbool( database_access->get_infotype( object_name ) IS NOT INITIAL ).
  ENDMETHOD.


  METHOD is_object_sw01_generate.
    result = xsdbool( database_access->get_table_object_repository( object_name ) IS NOT INITIAL ).
  ENDMETHOD.

ENDCLASS.



CLASS lcl_exemption_factory IMPLEMENTATION.

  METHOD get.
    CASE object_type.
      WHEN 'PROG'.
        result = NEW lcl_exemption_of_prog( database_access = database_access
                                            object_type     = object_type
                                            object_name     = object_name
                                            include         = include ).
      WHEN 'CLAS' OR 'INTF'.
        result = NEW lcl_exemption_of_clas( database_access = database_access
                                            object_type     = object_type
                                            object_name     = object_name
                                            include         = include ).
      WHEN 'FUGR'.
        result = NEW lcl_exemption_of_fugr( database_access = database_access
                                            object_type     = object_type
                                            object_name     = object_name
                                            include         = include ).
    ENDCASE.
  ENDMETHOD.

ENDCLASS.