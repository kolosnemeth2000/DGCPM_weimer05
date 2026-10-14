module ModUtilities
  implicit none

contains

  subroutine CON_set_do_test(NameSub, DoTest, DoTestMe)
    character(*), intent(in)  :: NameSub
    logical,      intent(in)  :: DoTest
    logical,      intent(out) :: DoTestMe

    DoTestMe = DoTest
  end subroutine CON_set_do_test


  subroutine CON_stop(message)
    character(*), intent(in) :: message
    print *, 'CON_stop:', trim(message)
    stop
  end subroutine CON_stop


  subroutine fix_dir_name(name)
    character(*), intent(inout) :: name
  end subroutine fix_dir_name


  subroutine check_dir(name)
    character(*), intent(in) :: name
  end subroutine check_dir


  subroutine lower_case(str)
    character(*), intent(inout) :: str
    integer :: i
    do i = 1, len_trim(str)
       if (str(i:i) >= 'A' .and. str(i:i) <= 'Z') then
          str(i:i) = achar(iachar(str(i:i)) + 32)
       end if
    end do
  end subroutine lower_case

end module ModUtilities
