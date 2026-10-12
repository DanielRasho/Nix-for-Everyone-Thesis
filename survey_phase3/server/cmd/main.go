package main

import (
	"context"
	"net/http"
	"time"

	"github.com/DanielRasho/Thesis/content"
	"github.com/DanielRasho/Thesis/internal/config"
	http_h "github.com/DanielRasho/Thesis/internal/handlers"
	"github.com/DanielRasho/Thesis/internal/middlewares"
	"github.com/DanielRasho/Thesis/internal/services/results_s"
	"github.com/DanielRasho/Thesis/internal/services/sessions_s"
	"github.com/DanielRasho/Thesis/internal/services/survey_s"
	"github.com/DanielRasho/Thesis/internal/services/users_s"
	postgres_cli "github.com/DanielRasho/Thesis/internal/storage"
	"github.com/DanielRasho/Thesis/internal/storage/survey_db"
	"github.com/DanielRasho/Thesis/utils"
	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
	"github.com/rs/zerolog/log"
)

// How long to wait for the DB at startup (it restarts once after the init
// scripts of a fresh volume).
const dbStartupTimeout = 60 * time.Second

func main() {

	// Load config
	godotenv.Load()
	apiPort := config.LoadRunningModeConfig()
	DBConfig := config.LoadDBConfig()
	loggingConfig := config.LoadLoggingConfig()
	corsConfig := config.LoadCorsConfig()
	adminConfig := config.LoadAdminConfig()
	sessionConfig := config.LoadSessionConfig()

	// Config logger
	utils.ConfigureLogger(&loggingConfig)

	ctx := context.Background()

	// Load survey content (server/content/*.yaml)
	surveyContent, err := content.Load()
	if err != nil {
		log.Fatal().Err(err).Msg("Invalid survey content")
		return
	}

	// Start DB Connection
	DBCli, err := postgres_cli.NewPGClient(ctx, DBConfig)
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to initialize UMS Postgres client")
		return
	}
	defer DBCli.Close()

	api := newAPI(DBCli, surveyContent, sessionConfig)

	// Admin account from ADMIN_USERNAME / ADMIN_PASSWORD
	if err := api.users.BootstrapAdmin(ctx, adminConfig.Username, adminConfig.Password, dbStartupTimeout); err != nil {
		log.Fatal().Err(err).Msg("Failed to bootstrap the admin account")
		return
	}
	log.Info().Str("username", adminConfig.Username).Msg("Admin account ready")

	// ROUTER
	r := chi.NewRouter()

	// MIDDLEWARES
	r.Use(middlewares.Logging) // first: one log line per request, recovers panics
	r.Use(middlewares.CreateCors(&corsConfig))
	r.Use(api.session)
	r.NotFound(http_h.NotFound)
	r.MethodNotAllowed(http_h.MethodNotAllowed)

	// ROUTES
	r.Get("/health", api.checkHealth)

	r.Route("/auth", func(r chi.Router) {
		r.Post("/login", api.postLogin)
		r.Post("/logout", api.postLogout)
		r.With(middlewares.RequireUser).Get("/me", api.getAuthMe)
	})

	// Participant
	r.Route("/me", func(r chi.Router) {
		r.Use(middlewares.RequireRole(survey_db.UserRoleParticipant))
		r.Get("/roadmap", api.getRoadmap)
		r.Get("/steps/{stepId}/current", api.getCurrent)
		r.Post("/answers", api.postAnswer)
		r.Post("/heartbeat", api.postHeartbeat)
	})

	// Admin
	r.Route("/admin", func(r chi.Router) {
		r.Use(middlewares.RequireRole(survey_db.UserRoleAdmin))
		r.Get("/surveys", api.getSurveys)
		r.Get("/participants", api.getParticipants)
		r.Post("/participants", api.postParticipant)
		r.Post("/participants/{id}/password", api.postParticipantPassword)
		r.Delete("/participants/{id}", api.deleteParticipant)
		r.Get("/grading", api.getGrading)
		r.Put("/grading", api.putGrading)
		r.Get("/export.csv", api.getExport)
		r.Get("/export-code.zip", api.getExportCode)
	})

	// Start server
	server := &http.Server{
		Addr:              ":" + apiPort,
		Handler:           r,
		ReadHeaderTimeout: 10 * time.Second,
	}
	log.Info().Msgf("Running on http %s", apiPort) // process-compose waits for this line
	log.Fatal().Err(server.ListenAndServe()).Msg("Server stopped")
}

type api struct {
	// SERVICES (needed at startup)
	users *users_s.UserService

	// MIDDLEWARES
	session func(http.Handler) http.Handler

	// HTTTP
	checkHealth http.HandlerFunc

	postLogin  http.HandlerFunc
	postLogout http.HandlerFunc
	getAuthMe  http.HandlerFunc

	getRoadmap    http.HandlerFunc
	getCurrent    http.HandlerFunc
	postAnswer    http.HandlerFunc
	postHeartbeat http.HandlerFunc

	getSurveys              http.HandlerFunc
	getParticipants         http.HandlerFunc
	postParticipant         http.HandlerFunc
	postParticipantPassword http.HandlerFunc
	deleteParticipant       http.HandlerFunc
	getGrading              http.HandlerFunc
	putGrading              http.HandlerFunc
	getExport               http.HandlerFunc
	getExportCode           http.HandlerFunc
}

func newAPI(dbCli *pgxpool.Pool, surveyContent *content.Content, sessionConfig config.SessionConfig) api {
	validator := utils.NewValidator()
	DbQueries := survey_db.New(dbCli)

	userService := &users_s.UserService{
		DBClient:  dbCli,
		DBQueries: DbQueries,
	}
	sessionService := &sessions_s.SessionService{
		DBClient:     dbCli,
		DBQueries:    DbQueries,
		TTL:          sessionConfig.TTL,
		CookieSecure: sessionConfig.CookieSecure,
	}
	surveyService := &survey_s.SurveyService{
		DBClient:  dbCli,
		DBQueries: DbQueries,
		Content:   surveyContent,
	}
	resultsService := &results_s.ResultsService{
		DBClient:  dbCli,
		DBQueries: DbQueries,
		Content:   surveyContent,
	}

	return api{
		users: userService,

		session: middlewares.Session(sessionService),

		checkHealth: http_h.GetHealth,

		postLogin:  http_h.PostLogin(validator, userService, sessionService),
		postLogout: http_h.PostLogout(sessionService),
		getAuthMe:  http_h.GetAuthMe,

		getRoadmap:    http_h.GetRoadmap(surveyService),
		getCurrent:    http_h.GetCurrent(surveyService),
		postAnswer:    http_h.PostAnswer(validator, surveyService),
		postHeartbeat: http_h.PostHeartbeat(validator, surveyService),

		getSurveys:              http_h.GetSurveys(surveyService),
		getParticipants:         http_h.GetParticipants(userService, surveyService),
		postParticipant:         http_h.PostParticipant(validator, userService, surveyService),
		postParticipantPassword: http_h.PostParticipantPassword(userService),
		deleteParticipant:       http_h.DeleteParticipant(userService),
		getGrading:              http_h.GetGrading(resultsService),
		putGrading:              http_h.PutGrading(validator, resultsService),
		getExport:               http_h.GetExport(resultsService),
		getExportCode:           http_h.GetExportCode(resultsService),
	}
}
