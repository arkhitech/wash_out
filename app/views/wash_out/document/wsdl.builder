xml.instruct!
xml.wsdl :definitions, 'xmlns' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:tns' => @namespace,
                'xmlns:soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
                'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                'xmlns:soap-enc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
                'name' => @service_name,
                'xmlns:tns' => @namespace do

  xml.wsdl :types do
    xml.tag! "xs:schema", :targetNamespace => @namespace, 'xmlns:tns' => @namespace, 'xmlns:xs' => 'http://www.w3.org/2001/XMLSchema' do
      defined = []
      @map.each do |operation, formats|
        (formats[:in] + formats[:out]).each do |p|
          wsdl_type xml, p, defined
        end
      end
    end
  end

  xml.wsdl :portType, :name => "#{@service_name}_port" do
    @map.each do |operation, formats|
      xml.operation :name => operation do
        xml.input :message => "tns:#{operation}"
        xml.output :message => "tns:#{formats[:response_tag]}"
      end
    end
  end

  xml.wsdl :binding, :name => "#{@service_name}_binding", :type => "tns:#{@service_name}_port" do
    xml.tag! "soap:binding", :style => 'document', :transport => 'http://schemas.xmlsoap.org/soap/http'
    @map.keys.each do |operation|
      xml.wsdl :operation, :name => operation do
        xml.tag! "soap:operation", :soapAction => operation
        xml.wsdl :input do
          xml.tag! "soap:body",
            :use => "literal",
            :namespace => @namespace
        end
        xml.wsdl :output do
          xml.tag! "soap:body",
            :use => "literal",
            :namespace => @namespace
        end
      end
    end
  end

  xml.wsdl :service, :name => @service_name do
    xml.wsdl :port, :name => "#{@service_name}_port", :binding => "tns:#{@service_name}_binding" do
      xml.tag! "soap:address", :location => send("#{@name}_action_url")
    end
  end

  @map.each do |operation, formats|
    xml.wsdl :message, :name => "#{operation}" do
      formats[:in].each do |p|
        xml.wsdl :part, wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
      end
    end
    xml.wsdl :message, :name => formats[:response_tag] do
      formats[:out].each do |p|
        xml.wsdl :part, wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
      end
    end
  end
end
