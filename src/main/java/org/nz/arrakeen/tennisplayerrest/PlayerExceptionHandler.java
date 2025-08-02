package org.nz.arrakeen.tennisplayerrest;

import java.time.ZonedDateTime;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import jakarta.servlet.http.HttpServletRequest;

@ControllerAdvice
public class PlayerExceptionHandler {

    @ExceptionHandler
    public ResponseEntity<PlayerErrorResponse> playerNotFoundHandler (PlayerNotFoundException exception, HttpServletRequest req) {

        PlayerErrorResponse error = new PlayerErrorResponse( ZonedDateTime.now(), HttpStatus.NOT_FOUND.value(),
                req.getRequestURI(), exception.getMessage()
        );

        return new ResponseEntity<> (error, HttpStatus.NOT_FOUND);

    }
}