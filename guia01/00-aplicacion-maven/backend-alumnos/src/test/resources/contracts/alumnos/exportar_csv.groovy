import org.springframework.cloud.contract.spec.Contract

Contract.make {
    description "GET /alumnos/export retorna CSV con los alumnos"

    request {
        method GET()
        url '/alumnos/export'
    }

    response {
        status OK()
        body("")
    }
}
