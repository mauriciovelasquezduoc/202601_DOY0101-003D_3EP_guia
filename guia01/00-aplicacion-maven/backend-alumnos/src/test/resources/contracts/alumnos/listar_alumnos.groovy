import org.springframework.cloud.contract.spec.Contract

Contract.make {
    description "GET /alumnos retorna lista vacía cuando no hay alumnos"

    request {
        method GET()
        url '/alumnos'
    }

    response {
        status OK()
        headers {
            contentType applicationJson()
        }
        body([])
    }
}
