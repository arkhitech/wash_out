xml.instruct!
xml.wsdl :definitions, 'xmlns' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:tns' => @namespace,
                'xmlns:soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
                'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                'xmlns:soap-enc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
                'name' => @service_name,
                'targetNamespace' => @namespace do
  xml.wsdl :types do
    xml.tag! "schema", :targetNamespace => @namespace, :xmlns => 'http://www.w3.org/2001/XMLSchema' do
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
      xml.wsdl :operation, :name => operation do
        xml.wsdl :input, :message => "tns:#{operation}", name: operation
        xml.wsdl :output, :message => "tns:#{formats[:response_tag]}", name: operation
      end
    end
  end

  xml.wsdl :binding, :name => "#{@service_name}_binding", :type => "tns:#{@service_name}_port" do
    xml.tag! "soap:binding", :style => 'rpc', :transport => 'http://schemas.xmlsoap.org/soap/http'
    @map.keys.each do |operation|
      xml.wsdl :operation, :name => operation do
        xml.tag! "soap:operation", :soapAction => operation
        xml.wsdl :input do
          xml.tag! "soap:body",
            :use => "encoded", :encodingStyle => 'http://schemas.xmlsoap.org/soap/encoding/',
            :namespace => @namespace
        end
        xml.wsdl :output do
          xml.tag! "soap:body",
            :use => "encoded", :encodingStyle => 'http://schemas.xmlsoap.org/soap/encoding/',
            :namespace => @namespace
        end
      end
    end
  end

  xml.wsdl :service, :name => "service" do
    xml.wsdl :port, :name => "#{@service_name}_port", :binding => "tns:#{@service_name}_binding" do
      xml.tag! "soap:address", :location => send("#{@service_name}_action_url")
    end
  end

  @map.each do |operation, formats|
    xml.wsdl :message, :name => "#{operation}" do
      formats[:in].each do |p|
        xml.part wsdl_occurence(p, true, :name => p.name, :type => p.namespaced_type)
      end
    end
    xml.wsdl :message, :name => formats[:response_tag] do
      formats[:out].each do |p|
        xml.part wsdl_occurence(p, true, :name => p.name, :type => p.namespaced_type)
      end
    end
  end
end
