# This test function is testing the 'get_player_archive_and_filter' function from the 'bq_load_player_games' module.
# The function takes a player's username, email, their game history, and an optional 'min_archive' parameter that 
# filters the player's game archives based on a minimum archive date.
# 
# The test uses mock data for the response from the Chess.com API to simulate different scenarios for filtering the archives:
# - If 'min_archive' is None, it should return all available archives without any date filtering.
# - If 'min_archive' is provided, the archives will be filtered to include only those after the specified date.
# - It also handles cases where the user has a history with the most recent archive URL, filtering the archives based on that.
# 
# The test is parametrized to run with different 'min_archive' values and user history to ensure the function behaves as expected 
# under various conditions.

import pytest
import pandas as pd
from unittest.mock import patch
from bq_load_player_games import get_player_archive_and_filter

# Mock response data from Chess.com API for the user 'test_user'
mock_archives = {
    "archives": [
        "https://api.chess.com/pub/player/test_user/games/2024/09",
        "https://api.chess.com/pub/player/test_user/games/2024/10",
        "https://api.chess.com/pub/player/test_user/games/2024/11",
        "https://api.chess.com/pub/player/test_user/games/2024/12",
        "https://api.chess.com/pub/player/test_user/games/2025/01",
        "https://api.chess.com/pub/player/test_user/games/2025/02",
    ]
}

# Parametrize test cases with different scenarios
@pytest.mark.parametrize("min_archive, username_history, expected_archives", [

    # Case 1: min_archive is None & No history → Return all archives without filtering by date
    (None, 
     pd.DataFrame(columns=["username", "latest_archive_url", "latest_end_time"]), 
     [
         "https://api.chess.com/pub/player/test_user/games/2024/09",
         "https://api.chess.com/pub/player/test_user/games/2024/10",
         "https://api.chess.com/pub/player/test_user/games/2024/11",
         "https://api.chess.com/pub/player/test_user/games/2024/12",
         "https://api.chess.com/pub/player/test_user/games/2025/01",
         "https://api.chess.com/pub/player/test_user/games/2025/02",
     ]
    ),

    # Case 2: min_archive = 2024/10 & No history → Return all archives, but filter on the min_archive value
    ("2024/10", 
     pd.DataFrame(columns=["username", "latest_archive_url", "latest_end_time"]), 
     [
         "https://api.chess.com/pub/player/test_user/games/2024/10",
         "https://api.chess.com/pub/player/test_user/games/2024/11",
         "https://api.chess.com/pub/player/test_user/games/2024/12",
         "https://api.chess.com/pub/player/test_user/games/2025/01",
         "https://api.chess.com/pub/player/test_user/games/2025/02",
     ]
    ), 

    # Case 3: User history exists with an older latest archive → Filter newer archives
    ("2024/10", 
     pd.DataFrame({
         "username": ["test_user"],
         "latest_archive_url": ["https://api.chess.com/pub/player/test_user/games/2024/11"],
     }),
     [
         "https://api.chess.com/pub/player/test_user/games/2024/11",
         "https://api.chess.com/pub/player/test_user/games/2024/12",
         "https://api.chess.com/pub/player/test_user/games/2025/01",
         "https://api.chess.com/pub/player/test_user/games/2025/02",
     ]
    ),

    # Case 4: User history exists with the most recent archive → Return only that one
    ("2024/10", 
     pd.DataFrame({
         "username": ["test_user"],
         "latest_archive_url": ["https://api.chess.com/pub/player/test_user/games/2025/01"],
     }),
     [
         "https://api.chess.com/pub/player/test_user/games/2025/01",
         "https://api.chess.com/pub/player/test_user/games/2025/02",
     ]
    ),

    # Case 6: User history exists with an even newer archive → Return empty list
    ("2024/10", 
     pd.DataFrame({
         "username": ["test_user"],
         "latest_archive_url": ["https://api.chess.com/pub/player/test_user/games/2025/03"],
     }),
     []
    ),
])

@patch("requests.get")  # Mock the API call
def test_get_player_archive_and_filter(mock_get, min_archive, username_history, expected_archives):

    # Set up mock response for the API call
    mock_get.return_value.json.return_value = mock_archives

    # Call the function under test with mocked data
    result = get_player_archive_and_filter("test_user", "test@example.com", username_history, min_archive)

    # Print the actual result vs expected
    print(f"Expected archives: {expected_archives}")
    print(f"Actual archives: {result['archives']}")

    # Assert that the returned archives match the expected output
    assert result["archives"] == expected_archives
